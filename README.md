# Bokashi

A privacy-aware screenshot tool for macOS.

> **Bokashi** (ぼかし) is the Japanese word for *blur* or *obscure*.
> Not to be confused with the composting method of the same name 🌱.

**Status:** v0.1.0 — first public release. Capture, annotate, and copy or save the result.

## Why another screenshot tool?

Existing OSS macOS screenshot tools either feel dated, are non-native (Electron / Qt), or lack thoughtful annotation and privacy features. Bokashi aims to be:

- **Native macOS** — Swift, SwiftUI / AppKit, ScreenCaptureKit. No Electron.
- **Annotation-first** — arrows, boxes, ellipses, lines, undo/redo. Designed to feel right.
- **Privacy-aware** — captures stay in memory; closing the editor copies them to your clipboard. Bokashi never writes a screenshot to disk unless you explicitly ask. Manual mosaic masking now, and automatic detection of sensitive information (with Japanese-language support) on the roadmap.
- **Open source** — MIT licensed. Hackable, contribution-friendly.

## Features

| Feature | Status |
|---|---|
| Menubar app + global hotkeys | ✅ |
| Full-screen / window / region capture | ✅ |
| Editor with clipboard-first save flow | ✅ |
| Annotation tools (arrow / box / ellipse / line) | ✅ |
| Color & stroke-width pickers, undo / redo | ✅ |
| Manual mosaic masking | Planned (M4) |
| Automatic sensitive-info detection (Japanese-aware) | Planned (M5) |
| Auto-update via Sparkle | Planned (M4) |

See [docs/ROADMAP.md](docs/ROADMAP.md) for the full plan and
[CHANGELOG.md](CHANGELOG.md) for release history.

## Install

Download the latest `Bokashi-vX.Y.Z.zip` from
[Releases](https://github.com/snaka/Bokashi/releases), unzip, and drag
`Bokashi.app` into `/Applications`.

The release is **ad-hoc signed**, so macOS Gatekeeper will warn the first
time you open it:

> "Bokashi" cannot be opened because it is from an unidentified developer.

To open it the first time:

- **Right-click** `Bokashi.app` → **Open** → click **Open** in the dialog.

  *or*

- Try to launch it once normally, then go to **System Settings → Privacy
  & Security**, scroll to the bottom, and click **Open Anyway**.

Subsequent launches work normally. A signed and notarized release will
replace this once the maintainer enrols in the Apple Developer Program.

On first capture, macOS will ask for **Screen Recording** permission;
grant it and re-launch Bokashi if prompted.

## Build from source

Bokashi uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`.

```sh
brew install xcodegen
git clone https://github.com/snaka/Bokashi.git
cd Bokashi
xcodegen
open Bokashi.xcodeproj
```

Or build from the command line:

```sh
xcodegen
xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build
```

The core logic lives as a local Swift package at `Packages/BokashiCore/` and can be tested independently:

```sh
swift test --package-path Packages/BokashiCore
```

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later (for building from source)

## License

[MIT](LICENSE)
