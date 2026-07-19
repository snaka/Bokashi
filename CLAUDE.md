# Bokashi — Notes for Claude / contributors

This file is auto-loaded by Claude Code when working in this repository.
Keep it concise and useful — it is not user-facing documentation.

## What this project is

Bokashi is a native macOS screenshot tool with annotation and privacy-masking
features, distributed as OSS under MIT. The name comes from the Japanese word
ぼかし (*blur*), reflecting the privacy-mask feature, which is the long-term
differentiator against Shottr / CleanShot X / Xnapper / Flameshot.

The user-facing pitch is in [`README.md`](README.md). The full roadmap is in
[`docs/ROADMAP.md`](docs/ROADMAP.md).

## Stack and conventions

- **Language:** Swift (latest stable). Use Swift Concurrency (`async`/`await`)
  for capture and IO paths.
- **UI:** SwiftUI primarily; drop to AppKit only when SwiftUI cannot express
  the needed behavior (transparent overlay windows for region selection,
  global hotkeys, menubar status item, etc.).
- **Capture API:** `ScreenCaptureKit`. Do not use the deprecated
  `CGWindowListCreateImage` family.
- **Deployment target:** macOS 26.0+ (raised from 14.0 in 2026-07 for the
  Foundation Models framework). Apple Intelligence availability must still
  be checked at runtime — macOS 26 runs on some Intel Macs and users can
  keep Apple Intelligence off.
- **Project generation:** [XcodeGen](https://github.com/yonaskolb/XcodeGen).
  The `.xcodeproj` is gitignored; edit `project.yml` and re-run `xcodegen`.
- **Module layout:**
  - `Bokashi/` — the macOS app target (UI, app delegate, menubar, capture
    overlay). Keep this layer thin.
  - `Packages/BokashiCore/` — local Swift package. Pure-Swift logic that
    can be unit-tested without an app host (annotation models, mask
    application, file IO helpers, etc.). Prefer putting code here.
- **Coding style:** Follow Swift API Design Guidelines. No comments unless
  the *why* is non-obvious. No emojis in code or commits.

## Common commands

```sh
# Generate Xcode project
xcodegen

# Build (Debug, unsigned, suitable for local dev)
xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO

# Run BokashiCore unit tests (no app host needed)
swift test --package-path Packages/BokashiCore
```

## Permissions and entitlements

- **Screen Recording** is required for capture. Ask via
  `CGRequestScreenCaptureAccess()` and surface a clear error if denied.
- **Accessibility** is *not* required for global hotkeys when using
  `KeyboardShortcuts` / Carbon `RegisterEventHotKey`.
- The app is configured as `LSUIElement` (menubar-only, no Dock icon).

## Code signing for local development

`project.yml` currently pins manual signing to the maintainer's free
Personal Team (`DEVELOPMENT_TEAM` + `CODE_SIGN_IDENTITY` SHA hash).
The hash is the maintainer's *Apple Development* certificate fingerprint;
it is not secret, but it only matches the maintainer's keychain.

A stable signing identity is what keeps macOS's TCC grants (Screen
Recording, Notifications, etc.) attached to the binary across rebuilds.
Without it, every Xcode build appears as a new app to TCC and silently
loses permission, forcing a `tccutil reset ScreenCapture com.snaka.Bokashi`
between iterations.

If you are not the maintainer and want to build locally, either:

1. Replace `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY` in `project.yml`
   with your own Apple Development certificate hash (find with
   `security find-identity -v -p codesigning`), or
2. Strip both keys plus `CODE_SIGN_STYLE: Manual` to fall back to
   ad-hoc signing — the app still builds, but TCC permissions will
   reset on each rebuild.

## What goes where

| Concern | Location |
|---|---|
| Annotation data model (value types) | `Packages/BokashiCore/Sources/BokashiCore/Annotation/` |
| Capture orchestration (ScreenCaptureKit wrappers) | `Bokashi/Capture/` |
| Region-select transparent overlay | `Bokashi/Capture/Overlay/` |
| Editor window and Canvas drawing | `Bokashi/Editor/` |
| Tool implementations (arrow / box / ellipse / line / mosaic) | `Bokashi/Editor/Tools/` |
| Export (PNG, clipboard) | `Packages/BokashiCore/Sources/BokashiCore/Export/` |
| Global hotkey registration | `Bokashi/Hotkey/` |
| Settings UI and persistence | `Bokashi/Settings/` |

This layout is aspirational — early milestones may flatten it. Don't create
empty directories ahead of need.

## Don't

- Don't add cross-platform abstractions (Linux/Windows). macOS only.
- Don't propose Mac App Store distribution unless the user revisits it.
  Distribution is GitHub Releases (Developer ID + notarized) → Homebrew Cask.
- Don't add cloud-upload features without an explicit ask. If users need
  uploads, they should configure their own destinations (S3 / Imgur / etc.).
- Don't introduce heavy dependencies for the auto-mask feature (no large
  ML model downloads). Vision framework + regex is the path; CoreML small
  models are acceptable if they ship inside the app bundle.

## Roadmap pointer

Milestones M0 (current — repo scaffolding) through M5 (auto-detect) are
listed in [`docs/ROADMAP.md`](docs/ROADMAP.md). Keep that file in sync when
milestones complete or scope changes.

## Cutting a release

Full procedure lives in [`RELEASE.md`](RELEASE.md); this is the short
playbook for when "publish a new version" comes up:

1. **Pick the next version.** Semver: feature-set bump = minor, bug fix
   = patch. Default to a minor bump (e.g. `0.4.0` → `0.5.0`) when one
   or more features have landed since the last tag.
2. **Confirm the tag is free.** `git ls-remote --tags origin` plus
   `gh release list`. If the chosen tag already exists on the remote,
   **do not force-push or delete it** — bump to the next minor instead
   and add a short note in `CHANGELOG.md` explaining the skip. (This
   exact case happened with v0.4.0; the fix was to ship as v0.5.0.)
3. **Prep PR.** Branch `chore/prep-vX.Y.Z`. Bump `MARKETING_VERSION`
   in `project.yml` and add a new `[X.Y.Z] - YYYY-MM-DD` section to
   `CHANGELOG.md` with the changes since the previous tag, grouped
   into Added / Changed / Fixed / Privacy / Notes. Close it out with a
   reference link at the bottom. Run `xcodegen` so the `.xcodeproj`
   stays in sync locally (the file itself is gitignored, but the run
   shakes out any project.yml typos).
4. **Merge the prep PR.** The user merges; the assistant does not
   `gh pr merge` shared-state PRs without an explicit request.
5. **Tag and push.** From `main`:
   ```sh
   git checkout main && git pull
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
   The `release.yml` workflow signs, notarizes, attaches a `.dmg` to a
   new GitHub Release, and updates the Homebrew cask formula in
   `snaka/homebrew-tap`. No further action.
6. **Watch the workflow.** `gh run watch` (or the Actions tab). On
   failure, see the Troubleshooting section in `RELEASE.md`.
