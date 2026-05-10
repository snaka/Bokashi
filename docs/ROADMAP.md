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
  - [x] Settings scene scaffolding + custom-term list (user-defined
        substrings auto-masked on capture, persisted as JSON in
        `~/Library/Application Support/Bokashi/custom-terms.json`)
  - [x] Bulk-register custom terms from a screen selection (region
        select → Vision OCR → reviewable list of detected lines)
- [x] Click-to-pick capture window with hover preview (#20) — Mission
  Control-style overlay; pre-captured snapshots are drawn inside the
  highlight cutout so occluded windows still show their real content
- [x] Multi-display support
  - [x] Region overlay spans every connected display; capture routes
        to the right display (#18)
  - [x] Full-screen capture targets the display the cursor is on (#19)
- Sparkle 2 auto-update
- Designed (rather than placeholder) app + menubar icons
- Mosaic block-size presets (small / medium / large)
- Expand annotation line-width presets from 3 to ~5 levels (currently
  thin / medium / thick in `AnnotationStyle.WidthPreset`)
- Text annotation tool (typed labels / captions on top of the image,
  with font-size and color controls)
- Eraser for placed masks (click a mosaic annotation to remove it,
  including ones added by auto-mask)
- Temporarily highlight masked regions in the editor (toggle to
  visualize which areas are masked, for last-mile coverage check
  before export)
- Pluggable sensitive-region detectors (privacy-first: every detector
  runs on-device; cloud LLM APIs are explicitly excluded)
  - [x] `SensitiveRegionDetector` protocol abstraction so OCR /
        CoreML / local-LLM detectors plug in uniformly (Phase 0)
  - [ ] Local CoreML detector for chat-app UI patterns (Slack /
        Twitter / Discord) — bundled or downloadable model packs
  - [ ] Optional Ollama-based vision LLM detector (user installs
        Ollama themselves; Bokashi only talks to localhost)
  - [ ] Per-detector toggle in Settings
- More auto-detectors: credit cards, IP addresses, AWS keys, My Number
- Reviewable detection candidates (preview boxes before applying)
- "N items masked" toast after auto-detect
- Submit to the official `homebrew/cask` repo (deferred until v1.0)
- Scrolling capture
- GIF / video capture (open question — may stay out of scope)
