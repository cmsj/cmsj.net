title: Lessons learned about using GitHub Actions to build macOS apps
slug: macgithubactions
date: 2021-04-12


## Introduction

[Hammerspoon](https://www.hammerspoon.org/) now has [per-commit development builds](https://github.com/Hammerspoon/hammerspoon/actions/workflows/ci_nightly.yml) generated automatically by a [GitHub Actions](https://github.com/features/actions) [workflow](https://github.com/Hammerspoon/hammerspoon/blob/master/.github/workflows/ci_nightly.yml).

This was a surprisingly slow and painful process to set up, so here are some things I learned along the way.

## I prefer scripts to actions

There are *tons* of third party GitHub Actions available in their [marketplace](https://github.com/marketplace?type=actions). Almost every time I use one, I come to regret it and end up switching to just running a bash script.

## More useful checkouts

If you want to do anything other than interact with the current code (e.g. access tag history) you'll find it fails. Add the `fetch-depth` argument to `actions/checkout`:

```yaml
  - name: Checkout foo
    uses: actions/checkout@v2
    with:
      fetch-depth:0
```

## Checking out a private repo from a public one is weirdly hard

Since these development builds are signed, they need access to a signing key. GitHub has a system for sharing secrets with a repo, but it's limited to 64KB values. For anything else, you need to encrypt the secrets in a repo and set a repository secret with the passphrase.

It seemed to me like it would be a good idea to keep the encrypted secrets in a private repository that the build process would check out, so the ciphertext is never exposed to the gaze of the Internet.

Unfortuantely, GitHub's [OAuth scopes](https://docs.github.com/en/developers/apps/scopes-for-oauth-apps) only allow you to give full read/write permission to all repositories a user can access, there's no way to grant read-only access.

So, I decided it was safer to just try and be extra-careful about how I encrypt my secrets, and keep them in a public repository.

## Code signing a macOS app in CI needs a custom keychain

The default login keychain requires a password to unlock, so if you put a signing certificate there, your CI builds will hang indefinitely waiting for a password to be entered into a UI dialog you can't see.

I took some ideas from the [devbotsxyz action](https://github.com/devbotsxyz/import-signing-certificate) and a couple of blog posts, to come up with [my own script](https://github.com/Hammerspoon/hammerspoon/blob/master/scripts/github-ci-nightly-keychain.sh) to create a keychain, unlock it, import the signing certificate, disable the keychain's lock timeout, and allow codesigning tools to use the keychain without a password.

## Xcode scrubs the inherited environment

Normally, you can use environment variables like `$GITHUB_ACTIONS` to determine if you're running in a CI-style situation. I use this for our test framework to [detect CI](https://github.com/Hammerspoon/hammerspoon/blob/master/Hammerspoon%20Tests/HSTestCase.m#L94) so certain tests can be skipped.

Unfortunately, it seems like `xcodebuild` scrubs the environment when running script build phases, so instead I created an empty file on disk that the build scripts could check for:

```yaml
  - name: Workaround xcodebuild scrubbing environment
    run: touch ../is_github_actions
```

This allows us to skip things like uploading debug symbols to Sentry.

## You can't upload artifacts from strange paths

The `actions/upload-artifact` action will refuse to upload any artifacts that have `../` or `./` in their path. I assume this is for security reasons, but that makes no sense because all you have to do is move/copy the file you want into the runner's `$PWD` and you can upload them:

```yaml
  - name: Prepare artifacts
    run: mv ../archive/ ./
  - name: Upload artifact
    uses: actions/upload-artifact@v2
    with:
      name: foo
      path: archive/foo
```

## It's pretty easy to verify your code signature, Gatekeeper acceptance, entitlements and notarization status

For Hammerspoon these are part of a more complex [release script library](https://github.com/Hammerspoon/hammerspoon/blob/master/scripts/librelease.sh), but in essence these are the commands that you can use to either check return codes, or outputs, for whether your app is as signed/notarized/entitled as you expect it to be:

```bash
# Check valid code signature
if ! codesign --verify --verbose=4 "/path/to/Foo.app" ; then
  echo "FAILED: Code signature check"
fi

# Check valid code signing entity
MY_KNOWN_GOOD_ENTITY="Authority=Developer ID Application: Jonny Appleseed (ABC123ABC)"
ACTUAL_SIGNER=$(codesign --display --verbose=4 "/path/to/Foo.app" 2>&1 | grep ^Authority | head -1)
if [ "${ACTUAL_SIGNER}" != "${MY_KNOWN_GOOD_ENTITY}" ]; then
  echo "FAILED: Code signing authority"
fi

# Check Gatekeeper acceptance
if ! spctl --verbose=4 --assess --type execute "/path/to/Foo.app" ; then
  echo "FAILED: Gatekeeper acceptance"
fi

# Check Entitlements match
EXPECTED=$(cat /path/to/source/Foo.entitlements)
ACTUAL=$(codesign --display --entitlements :- "/path/to/Foo.app")
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  echo "FAILED: Entitlements"
fi
```

I do these even on local release builds, to ensure nothing was missed before pushing out a release, but they also make sense to do in CI.

## That's it

Not a ground-shaking set of things to learn, but combined they took several hours to figure out, so maybe this post saves someone else some time.

