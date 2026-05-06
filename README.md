<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Bokashi app icon" />
</p>

<h1 align="center">Bokashi</h1>

<p align="center">A privacy-aware screenshot tool for macOS.</p>

> **Bokashi** (ぼかし) is the Japanese word for *blur* or *obscure*.
> Not to be confused with the composting method of the same name 🌱.

**Status:** v0.3.0 — adds on-device sensitive-info detection (one-click and click-to-mask) on top of the v0.2.0 mosaic flow.

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
| Manual mosaic masking | ✅ |
| On-device sensitive-info detection (email / phone / address / name) | ✅ |
| Click-to-mask any OCR'd text region | ✅ |
| Auto-mask on capture (menubar toggle) | ✅ |
| Developer ID signed + notarized releases | ✅ |
| Homebrew Cask install (`snaka/tap/bokashi`) | ✅ |
| Auto-update via Sparkle | Planned (later) |

See [docs/ROADMAP.md](docs/ROADMAP.md) for the full plan and
[CHANGELOG.md](CHANGELOG.md) for release history.

## Install

### Homebrew (recommended)

```sh
brew install --cask snaka/tap/bokashi
```

This pulls the latest signed and notarized `.dmg` from
[Releases](https://github.com/snaka/Bokashi/releases) via the
[`snaka/homebrew-tap`](https://github.com/snaka/homebrew-tap) tap.

### Manual download

Download the latest `Bokashi-X.Y.Z.dmg` from
[Releases](https://github.com/snaka/Bokashi/releases), open it, and drag
`Bokashi.app` into `/Applications`.

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
