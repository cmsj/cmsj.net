title: A simple Swift extension for dev_t to get the major/minor numbers
slug: swift_devt_major_minor
date: 2025-07-18

This is a post that serves mostly to try and seed Google with an answer to a question I had, that I couldn't find an existing answer to.

I was working on some macOS Swift code that needed to care about UNIX device nodes (ie block/character devices), which are represented via the `dev_t` type.
What I specifically needed was to be able to extract the major and minor node numbers from a `dev_t`, and that's what this does:

```swift
import Darwin

extension dev_t {
    func major() -> Int32 {
        return (self >> 24) & 0xff
    }

    func minor() -> Int32 {
        return self & 0xffffff
    }

    var description: String {
        let major = String(major(), radix: 16)
        let minor = String(minor(), radix: 16)
        return "\(major), \(minor)"
    }
}
```