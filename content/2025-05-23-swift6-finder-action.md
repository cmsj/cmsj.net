title: Writing a macOS Finder "action" extension with Swift 6 concurrency
slug: finder-action-swift6
date: 2025-05-23


Swift 6 is great, but the strict concurrency checking can make interactions with older Apple APIs be... not fun.

Furthermore, older Apple APIs can be less aware of Swift's `async` features, which becomes particularly relevant if you have adopted `actor` objects, since access to those is *always* async.. I recently ran into a situation like this while adding a Finder "action extension" to an app I'm working on, where the code that does the "action" is in an `actor`.

Apple provides [sample code](https://developer.apple.com/documentation/appkit/add-functionality-to-finder-with-action-extensions) for writing Finder extensions, but it assumes the actual work to be done, is synchronous. Since there wasn't a ton of relevant info online already, I figured I'd blog about it in the hopes that it can save some time for the next person who needs to do this.

Rather than make this blog post huge, I've just added lots of comments to the code so you can follow it in-place. The context is that we are writing an extension that can extract compressed archives (e.g. Zip files) and all of the actual code for interacting with archive files, is in an actor so the UI in our main app stays performant even with very large archives. You are invited to compare this code to Apple's sample code above, to see what my changes actually are.

```swift
//
//  ActionRequestHandler.swift
//  ExtractAction
//
//  Created by Chris Jones on 22/05/2025.
//

import Foundation
import UniformTypeIdentifiers
import Synchronization

// This is a helper function that will instantiate our actor, call it with the url from Finder that
// we're extracting, and then return the URL we wrote the archive's contents to.
func extract(_ url: URL) async throws -> URL? {
    // This first FileManager call is super weird, but it gives you a private, temporary
    // directory to use to write your output files/folders to.
    // It's super weird because we don't tell it anything about the action we're currently
    // responding to, and the directory it creates is accessible only by our code - the user can't 
    // go into this directory, nor can root.
    // Somehow macOS knows what we're doing and gives us an appropriate directory. I have put no
    // effort into trying to understand that, it is what it is.
    let itemReplacementDirectory = try FileManager.default.url(for: .itemReplacementDirectory,
                                                               in: .userDomainMask,
                                                               appropriateFor: URL(fileURLWithPath: NSHomeDirectory()),
                                                               create: true)

    // Now add the name of the archive (the last path component of `url`) to our temporary
    // directory, and create that directory. This is where we'll tell our actor to extract to
    let outputFolderName = url.deletingPathExtension().lastPathComponent.deletingPathExtension
    var outputFolderURL = itemReplacementDirectory.appendingPathComponent(outputFolderName)
    try FileManager.default.createDirectory(at: outputFolderURL, withIntermediateDirectories: true)

    // Now create our actor and ask it to extract the archive for us
    let someActor = ArchiveExtractor(for: url)
    await someActor.extract(to: outputFolderURL)

    // Return our extraction directory so the handler below can tell Finder about it.
    // Finder will then take care of moving it to the directory the user is in, renaming it
    // if any duplicates exist, and offering the user the opportunity to change the name.
    return outputFolderURL
}

// This is the class that implements the Finder extension
class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        NSLog("beginRequest(): Starting up...")

        // Get the input item from Finder
        guard let inputItem = context.inputItems.first as? NSExtensionItem else {
            preconditionFailure("beginRequest(): Expected an extension item")
        }

        // Get the "attachments" from the input item. These are NSItemProviders representing the 
        // file(s) selected by the user
        guard let inputAttachments = inputItem.attachments else {
            preconditionFailure("beginRequest(): Expected a valid array of attachments")
        }
        precondition(inputAttachments.isEmpty == false, "beginRequest(): Expected at least one attachment")

        // Similar to Finder giving us NSItemProvider objects for our input files, we also have to create
        // NSItemProvider objects for our output files.
        // Below we will do that through a complex arrangement of two callback methods which do not
        // guarantee that they are called on the main thread. Because of that lack of guarantee, we need
        // to ensure we are thread-safe, which we will do be creating a Mutex-wrapped array to store our
        // output NSItemProviders in.
        let outputAttachmentsStore: Mutex<[NSItemProvider]> = Mutex([])

        // This is how we will schedule our final work to be done after all of our output attachments
        // have finished doing their callback closures. More on this later.
        let dispatchGroup = DispatchGroup()

        // Iterate the incoming NSItemProviders
        for attachment in inputAttachments {
            // Tell the dispatch group that we're starting a new piece of work
            // (you can also think of this as incrementing a reference counter)
            dispatchGroup.enter()

            // Before we can call loadInPlaceFileRepresentation below, we need to know what UTType it
            // should load. Usually you'll already know what this is because you operate on one type
            // of file.
            // In my case, I need to operate on multiple UTTypes, so rather than repeat all this code
            // for ~20 types of archive, I just grab the UTType of the incoming NSItemProvider and
            // use that to load the FileRepresentation
            guard let attachmentTypeID = attachment.registeredTypeIdentifiers.first else { continue }
            NSLog("beginRequest(): Discovered source type identifier: \(attachmentTypeID)")

            // This uses the input NSItemProvider to locate the file it relates to and pass it to our closure.
            // The closure's job is to create an NSItemProvider that can be handed back to Finder, and that provider
            // is responsible for producing our output file.
            _ = attachment.loadInPlaceFileRepresentation(forTypeIdentifier: attachmentTypeID) { (url, inPlace, error) in
                // Once we have finished creating the NSItemProvider, signal to the DispatchGroup
                // that we've finished a piece of work (ie decrement the reference counter)
                defer { dispatchGroup.leave() }

                guard let url = url else {
                    NSLog("beginRequest(): Unable to get URL for attachment: \(error?.localizedDescription ?? "UNKNOWN ERROR")")
                    return
                }
                NSLog("beginRequest(): Found URL: \(url)")

                // Enter a context where we have safe access to the contents of our Mutex
                outputAttachmentsStore.withLock { outputAttachments in
                    let itemProvider = NSItemProvider()

                    // The loadHandler closure for this output NSItemProvider is where we'll call our 
                    // helper function from earlier.
                    NSLog("beginRequest(): Registering file representation...")
                    itemProvider.registerFileRepresentation(forTypeIdentifier: UTType.data.identifier,
                                                            fileOptions: [.openInPlace],
                                                            visibility: .all,
                                                            loadHandler: { completionHandler in
                        NSLog("beginRequest(): in registerFileRepresentation loadHandler closure")

                        // We can't just directly await our extract() helper function here because we're in a
                        // syncronous context, not an async one, so we need a Task, but if we just ask for a Task
                        // on our current thread, it will never execute because the thread will be blocked waiting for it.
                        // So, we will ask for a detached, ie background, Task to do our work and call the completion handler.
                        Task.detached {
                            NSLog("beginRequest(): in Task")
                            do {
                                // Now we're in a Task we have an async context, so we can finally call our
                                // extraction helper function from above
                                let writtenURL = try await extract(url)
                                completionHandler(writtenURL, false, nil)
                            } catch {
                                completionHandler(nil, false, error)
                            }
                        }
                        return nil
                    })

                    // Store the output NSItemProvider in our thread-safe storage.
                    // Note that at this point, the callback above hasn't actually run yet, and doesn't run until
                    // Finder is ready to call it at some point in the future.
                    outputAttachments.append(itemProvider)
                    NSLog("beginRequest(): Adding provider output, there are now \(outputAttachments.count) providers")
                }
            }
        }

        // This is the second piece of the DispatchGroup magic.
        // This schedules a closure to run on the main queue when the DispatchGroup
        // has been drained of tasks (ie the reference counter has reached zero).
        // We can't do something like dispatchGroup.wait() because that would block the queue
        // and prevent the various NSItemProvider callbacks from executing.
        // Instead, the main queue of this extension's process just keeps ticking along
        // until the final call to dispatchGroup.leave().
        // This means you can deadlock the process if that never happens, but that
        // should only happen if your actor gets stuck indefinitely.
        dispatchGroup.notify(queue: DispatchQueue.main) {
            NSLog("beginRequest(): DispatchGroup completed")

            // This is the thing we have to return to Finder, and it will contain attachments for all of the
            // NSItemProviders we want to have exist.
            let outputItem = NSExtensionItem()

            let result = outputAttachmentsStore.withLock { (outputAttachments: inout sending [NSItemProvider]) -> [NSItemProvider] in
                // Action Extensions have an interesting quirk - if you don't return all of the input files
                // Finder will assume you've transformed them and will delete them. We don't want that, so we
                // will check we're not going to miss any.
                if inputAttachments.count < outputAttachments.count {
                    NSLog("beginRequest(): Did not find enough output attachments")
                    return []
                }

                // We can't return `outputAttachments` because it's isolated by the Mutex, but we know no further
                // changes will happen at this point, and NSItemProvider conforms to NSCopying, 
                // so we can just return an array of copies that is free of any isolation issues.
                return outputAttachments.compactMap { $0.copy() as? NSItemProvider }
            }

            if result.isEmpty {
                context.cancelRequest(withError: ArkyveError(.extract, msg: "Unable to extract archive"))
                return
            }

            // As mentioned above, we want to tell Finder to not delete all of the input files
            // So we return those NSItemProviders as well as the ones we created.
            outputItem.attachments = inputAttachments + result

            NSLog("beginRequest(): Success, calling completion handler")
            context.completeRequest(returningItems: [outputItem], completionHandler: nil)
        }
    }
}

```
