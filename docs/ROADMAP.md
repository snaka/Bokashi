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

## M4 — Privacy masking (manual) → v0.2.0

- [ ] Mosaic tool (rectangle selection, `CIPixellate`)
- [ ] Mosaic stays as an editable annotation layer until export
- [ ] Settings UI (save destination, hotkeys via `KeyboardShortcuts`)
- [ ] Sparkle 2 auto-update
- [ ] Developer ID signing + notarization in CI
- [ ] **v0.2.0 release with `.dmg`**

## M5 — Automatic sensitive-info detection (opt-in) → v0.3.0

- [ ] Vision OCR on captured image (`VNRecognizeTextRequest`)
- [ ] Regex-based detectors: email, phone, credit-card-like sequences,
      IP address, AWS-key-like strings
- [ ] Japanese-aware detectors: address patterns, My Number, common name
      patterns (initial heuristic; CoreML model possible later)
- [ ] Candidate boxes shown to the user; one click to mask
- [ ] Fully off by default; explicit opt-in setting
- [ ] **v0.3.0 release — the differentiator**

## Beyond M5

- Homebrew Cask submission
- Scrolling capture
- GIF / video capture (open question — may stay out of scope)
