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
- [x] One global hotkey (`⌃⌥⇧3` for full screen)

## M2 — Capture modes ✅

- [x] Window selection capture (`SCShareableContent.windows`)
- [x] Region selection via transparent overlay window
- [x] Per-mode hotkeys (`⌃⌥⇧4` for region; window picker is menu-driven)

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

## Backlog

Unscheduled work, grouped by theme. Items move out of here when they get
folded into a release prep PR.

### Polish / UX

- Editor window minimum size clamped so the toolbar always fits
  (recovering a hidden toolbar is fiddly; set `contentMinSize` on the
  window so it cannot be made smaller than the toolbar in the first
  place)
- Copy to clipboard immediately on capture, before the editor opens; the
  existing Done-on-export copy still runs afterward and overwrites with
  the annotated image (so "paste right away" and "edit, then paste"
  both work without extra clicks)
- Hotkey rebinding UI via `KeyboardShortcuts`
- Configurable save destination in Settings
- Designed (rather than placeholder) app + menubar icons
- Mosaic block-size presets (small / medium / large)
- Text annotation tool (typed labels / captions on top of the image,
  with font-size and color controls)
- Eraser for placed masks (click a mosaic annotation to remove it,
  including ones added by auto-mask)
- Temporarily highlight masked regions in the editor (toggle to
  visualize which areas are masked, for last-mile coverage check
  before export)
- "N items masked" toast after auto-detect

### Update mechanism

- Sparkle: Settings toggle for automatic background checks (currently
  manual-only; `SUEnableAutomaticChecks` defaults to false)

### Detection

Privacy-first: every detector runs on-device; cloud LLM APIs are
explicitly excluded.

- Reviewable detection candidates (preview boxes before applying)
- Local CoreML detector for chat-app UI patterns (Slack / Twitter /
  Discord) — bundled or downloadable model packs
- More auto-detectors: credit cards, IP addresses, AWS keys, My Number

### Distribution / CI

- Submit to the official `homebrew/cask` repo (deferred until v1.0)
- CI maintenance: migrate `release.yml` actions (`actions/checkout`,
  `actions/upload-artifact`, `softprops/action-gh-release`) off
  Node.js 20 before 2026-09-16 when Node 20 is removed from runners
  (deprecation warning surfaced in the v0.5.0 release run)

### Open questions

- Scrolling capture
- GIF / video capture (may stay out of scope)
