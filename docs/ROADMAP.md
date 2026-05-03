# Roadmap

Bokashi is built in small, releasable increments. Each milestone ends with
a tagged GitHub release where useful.

## M0 — Repository scaffolding (current)

- [x] License (MIT), README, CLAUDE.md, .gitignore
- [x] XcodeGen `project.yml`
- [x] App target skeleton (menubar entry, no real capture yet)
- [x] `BokashiCore` local Swift package with one passing test
- [x] CI: GitHub Actions running `xcodegen` + `xcodebuild` + `swift test`

## M1 — Minimum viable capture

- [ ] Menubar status item (`NSStatusItem`)
- [ ] Full-screen capture via `ScreenCaptureKit`
- [ ] Save PNG to `~/Desktop` (configurable later)
- [ ] Screen Recording permission request flow
- [ ] One global hotkey (configurable in code; settings UI comes later)

## M2 — Capture modes

- [ ] Window selection capture (`SCShareableContent.windows`)
- [ ] Region selection via transparent overlay window
- [ ] Per-mode hotkeys

## M3 — Annotation editor → v0.1.0

- [ ] Editor window opens after each capture
- [ ] Tools: arrow, box (filled / outlined), ellipse (filled / outlined), line
- [ ] Color and stroke-width controls
- [ ] Undo / redo via `UndoManager`
- [ ] Copy to clipboard, save PNG
- [ ] **First public release: v0.1.0 on GitHub Releases**

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
