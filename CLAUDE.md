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
- **Deployment target:** macOS 14.0+. Do not introduce APIs that require
  newer versions without discussion.
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

### Dev-only gotcha: Screen Recording permission resets on rebuild

Each Xcode build produces a new ad-hoc signing identity. macOS's TCC
database keys Screen Recording grants by signing identity, so every
rebuild appears as a "new app" and silently loses permission — even
though System Settings still shows the toggle as ON. The fix is to
toggle Bokashi OFF then ON again in *System Settings → Privacy &
Security → Screen Recording* after each rebuild. Production builds
signed with a stable Developer ID do not have this issue.

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
