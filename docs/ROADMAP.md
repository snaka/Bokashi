# Roadmap

Bokashi is built in small, releasable increments. Each milestone ends with
a tagged GitHub release where useful.

## M0 — Repository scaffolding ✅

- [x] License (MIT), README, CLAUDE.md, .gitignore
- [x] XcodeGen `project.yml`
- [x] App target skeleton (menubar entry, no real capture yet)
- [x] `BokashiCore` local Swift package with one passing test
- [x] CI: GitHub Actions running `xcodegen` + `xcodebuild` + `swift test`

## M1 — Minimum viable capture ✅

- [x] Menubar status item (via SwiftUI `MenuBarExtra`)
- [x] Full-screen capture via `ScreenCaptureKit`
- [x] Screen Recording permission request flow
- [x] One global hotkey (`⌃⌥⇧4` for full screen)

## M2 — Capture modes ✅

- [x] Window selection capture (`SCShareableContent.windows`)
- [x] Region selection via transparent overlay window
- [x] Per-mode hotkeys (`⌃⌥⇧6` for region; window picker is menu-driven)

## M3 — Annotation editor → v0.1.0 ✅

- [x] Editor window opens after each capture
- [x] Clipboard-first save flow (Done/Save…/Discard); no auto-save to disk
- [x] Tools: arrow, box (filled / outlined), ellipse (filled / outlined), line
- [x] Color and stroke-width controls
- [x] Undo / redo via `UndoManager`
- [x] **First public release: v0.1.0 on GitHub Releases**

## M4 — Privacy masking (manual) → v0.2.0 ✅

- [x] Mosaic tool (rectangle selection, `CIPixellate`)
- [x] Mosaic stays as an editable annotation layer until export
- [x] **v0.2.0 release on GitHub Releases** (mosaic only; Settings UI,
      Sparkle, and signed distribution deferred — see *Beyond M5*)

## M5 — Automatic sensitive-info detection (opt-in) → v0.3.0 ✅

- [x] Vision OCR on captured image (`VNRecognizeTextRequest`)
- [x] Email detection (regex)
- [x] Phone numbers and postal addresses (`NSDataDetector` — replaces
      the originally-planned per-locale regex)
- [x] Personal names (`NLTagger` `.nameType` with `.joinNames`,
      Japanese supported — replaces the planned heuristic / CoreML
      model)
- [x] Click-to-mask any OCR'd text region (the more general companion
      to auto-detect; covers anything OCR finds)
- [x] Auto-mask-on-capture toggle in the menubar (opt-in, persisted)
- [x] **v0.3.0 release on GitHub Releases**

Detector classes still on the wish list for later: credit-card-like
sequences, IP addresses, AWS-key-like strings, Japanese My Number.
`NSDataDetector` already covers most non-email patterns at a higher
quality than regex would, so further detectors get evaluated case by
case rather than as a single batch.

## Beyond M5

- [x] Developer ID signing + notarization in CI
- [x] Homebrew Cask distribution via [`snaka/homebrew-tap`](https://github.com/snaka/homebrew-tap)
      (`brew install --cask snaka/tap/bokashi`)
- Settings UI (save destination, hotkey rebinding via `KeyboardShortcuts`)
- Sparkle 2 auto-update
- Designed (rather than placeholder) app + menubar icons
- Mosaic block-size presets (small / medium / large)
- More auto-detectors: credit cards, IP addresses, AWS keys, My Number
- Reviewable detection candidates (preview boxes before applying)
- "N items masked" toast after auto-detect
- Submit to the official `homebrew/cask` repo (deferred until v1.0)
- Scrolling capture
- GIF / video capture (open question — may stay out of scope)
