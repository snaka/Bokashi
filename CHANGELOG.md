# Changelog

All notable changes to Bokashi are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.1] - 2026-05-31

A small fix to the window picker.

### Fixed

- **Window picker now targets the window you actually see.** When
  windows overlap, hovering and clicking resolve to the front-most
  window under the cursor instead of one hidden behind it. Previously
  an occluded window could be selected and jump to the front, making
  the window you meant to capture hard to pick. `SCShareableContent`
  does not guarantee z-order, so candidates are now ordered
  front-to-back via the on-screen window list before hit-testing.

## [0.8.0] - 2026-05-30

A polish-and-papercut release. Capture-mode hotkeys realign to the
macOS digit conventions, the menu bar finally shows what those combos
are, the raw capture is on your clipboard the moment you press the
shortcut, and Sparkle's automatic update check is now flippable from
Settings.

### Added

- **Clipboard-on-capture.** The raw screenshot is copied to the
  clipboard the instant capture completes, before the editor opens.
  The existing *Copy & Close* flow still overwrites with the annotated
  image when you confirm, so "paste right away" and "edit, then paste"
  both work without extra clicks.
- **Window-capture hotkey.** New default `⌃⌥⇧5` triggers the
  click-to-pick window flow, joining full-screen and region as a
  first-class shortcut. Configurable through `UserDefaults` /
  KeyboardShortcuts.
- **Hotkey hints in the menu bar.** Each *Capture* item shows its
  bound combo on the right (e.g. `⌃⌥⇧3`), so you no longer have to
  remember the mapping. Hints follow whatever combo is currently
  bound, ready for the future Settings rebinder.
- **"N items masked" toast.** After the editor's *Detect* button
  finishes, a transient banner reports either the count of new masks
  or "No sensitive info detected". Auto-mask-on-capture stays silent
  on empty results so it doesn't toast every screenshot.
- **Automatic update-check toggle.** New *Settings → General* tab with
  a *Check for updates automatically* switch bound to Sparkle's
  `SPUUpdater.automaticallyChecksForUpdates`. Default stays off so
  the first launch behavior is unchanged; flip it on and Sparkle
  starts polling the appcast in the background.

### Changed

- **Capture hotkey digits aligned with macOS.** Defaults are now
  `⌃⌥⇧3` (full screen), `⌃⌥⇧4` (region), `⌃⌥⇧5` (window) — mirroring
  the system's `⇧⌘3 / ⇧⌘4 / ⇧⌘5` mapping so the digit is recallable.
  Previous defaults were `⌃⌥⇧4 / ⌃⌥⇧6 / ⌃⌥⇧5`. The `⌃⌥⇧` prefix is
  retained so we don't clash with the reserved system shortcuts.
  A one-shot migration runs on first launch of v0.8.0: if your
  persisted shortcut still matches the previous default, it is
  rewritten to the new default; explicitly-customized values are left
  alone. After migration, the schema is marked and never re-runs.
- **Editor window minimum size now respects the toolbar.** The
  toolbar's natural width is measured at runtime and used as the
  window's `contentMinSize`, so resizing can no longer hide any
  toolbar control behind the chevron overflow.
- **Menu bar version string** reads `CFBundleShortVersionString` from
  the app bundle instead of a hand-maintained constant. The v0.7.0
  build shipped showing `Bokashi v0.0.0` because that constant had
  never been bumped; with this change the menu follows
  `MARKETING_VERSION` automatically on every release.

### Notes

- Builds on macOS 14+. No bundle identifier or signing identity
  changes; the v0.7.0 → v0.8.0 update goes through Sparkle's
  normal signed appcast flow.

[0.8.1]: https://github.com/snaka/Bokashi/releases/tag/v0.8.1
[0.8.0]: https://github.com/snaka/Bokashi/releases/tag/v0.8.0

## [0.7.0] - 2026-05-12

First release that exercises Sparkle's full download / install flow:
users on v0.6.0 should see "Check for Updates…" surface this version
and walk through the prompt, signature verification, and relaunch.

### Added

- **Five line-width presets** in the annotation toolbar. Replaces the
  previous thin / medium / thick ladder with hairline (1pt) / thin
  (3pt) / medium (6pt) / thick (10pt) / heavy (16pt). `medium` keeps
  its 6pt width so existing default-styled annotations look
  identical. (#27)

[0.7.0]: https://github.com/snaka/Bokashi/releases/tag/v0.7.0

## [0.6.0] - 2026-05-12

This release ships **Sparkle 2 auto-update infrastructure** and nothing
else user-facing. Existing v0.5.0 installs predate Sparkle and cannot
self-update — run `brew upgrade --cask snaka/tap/bokashi` (or download
the v0.6.0 DMG manually) one last time. From v0.6.0 onwards,
"Check for Updates…" in the menubar talks to the signed appcast at
<https://snaka.github.io/Bokashi/appcast.xml>.

### Added

- **Sparkle 2 auto-update plumbing.** New `Check for Updates…` entry
  in the menubar invokes Sparkle, which fetches a signed appcast,
  verifies the new DMG's EdDSA signature, and offers to install. (#25)
  - Automatic background checks are intentionally **off** in this
    release (`SUEnableAutomaticChecks = false`); a Settings toggle to
    flip them on is on the roadmap.
  - The release pipeline now signs every DMG with Sparkle's
    `sign_update` and appends an entry to `docs/appcast.xml` so the
    public feed always lists the latest version.

### Privacy

- The Sparkle feed is hosted on GitHub Pages from this repo. The only
  network call on update check is GET against that public XML; no
  user identifier is sent.

[0.6.0]: https://github.com/snaka/Bokashi/releases/tag/v0.6.0

## [0.5.0] - 2026-05-12

Skips v0.4.0 — that tag was already published earlier and is left
untouched. This release bundles everything since v0.3.0 under a fresh
minor version.

### Added

- **User-defined custom mask terms.** New *Custom Terms* tab in
  Settings (⌘,) where you register literal strings — your own name,
  company, product code, etc. They are masked automatically when
  found in a captured screenshot. Matching is case-insensitive and
  matches the substring exactly as entered, so registering `Hoge`
  masks just the `Hoge` portion of `HogeFuga`. Persisted as JSON at
  `~/Library/Application Support/Bokashi/custom-terms.json`. (#17)
- **Bulk-register custom terms from a screen selection.** Drag-select
  a region on screen and Vision OCR extracts every visible line; pick
  which ones become custom terms via a checkbox list with inline
  edit. (#17)
- **Multi-display support.**
  - Region selection now covers every connected display; the overlay
    spans every screen and capture routes to the correct one. (#18)
  - Full-screen capture targets the display the cursor is currently
    on instead of always grabbing the main display. (#19)
- **Click-to-pick capture window with hover preview.** Mission
  Control-style overlay replaces the menu-driven window list:
  hover any window to see a blue outline and the window's *actual
  contents* drawn inside the cutout. Buried / occluded windows still
  show their real content (snapshots are pre-captured upfront via
  `SCContentFilter(desktopIndependentWindow:)`). Click to capture,
  Esc to cancel. (#20)
- **Optional Ollama vision-LLM detector.** New *Detectors* tab in
  Settings can route the captured image through an Ollama instance
  running on your machine for vision-LLM-based PII detection.
  Configure endpoint (default `http://localhost:11434`) and model
  name (e.g. `llama3.2-vision`, `qwen2-vl`, `MiniCPM-V`); the *Test
  Connection* button verifies the endpoint is reachable and the
  model is pulled. Detection failures (unreachable / model missing /
  malformed response) are silent — the OCR detector still
  completes. (#22)
- **Developer-mode mask source overlay.** A *Highlight mask source*
  toggle in Settings outlines each auto-detected mosaic with a
  colored dashed border in the editor — blue for OCR-based detection
  and orange for Ollama. Useful baseline for tuning prompts and
  comparing detectors. (#22)

### Changed

- The OCR / regex / NLTagger detection path is now one implementation
  of a new `SensitiveRegionDetector` protocol. Future detectors
  (local CoreML model packs, etc.) slot into the same pipeline. No
  user-visible behavior change. (#21)

### Privacy

- All detectors run **on-device**. The Ollama detector talks only to
  the endpoint you configure (default localhost); no cloud-LLM
  integrations exist and none are planned.

[0.5.0]: https://github.com/snaka/Bokashi/releases/tag/v0.5.0

## [0.3.0] - 2026-05-04

### Added

- **One-click sensitive-info auto-mask.** A new *Detect* button in the
  editor toolbar runs Vision OCR on the captured image and turns each
  detected match into a mosaic annotation as a single undo step.
  Detection covers:
  - Email addresses (regex)
  - Phone numbers (`NSDataDetector`, multi-format)
  - Postal addresses (`NSDataDetector`)
  - Personal names (`NLTagger` with `.joinNames`, supports Japanese)
- **Click-to-mask any text region.** With the Mosaic tool selected, a
  click on any OCR-detected text masks just that text region. Drag
  still produces a freeform rectangle.
- **"Auto-mask sensitive info on capture" toggle** in the menubar.
  When on, every capture opens with the auto-mask pass applied.
  Persisted via `UserDefaults`.
- **App icon and menubar icon.** Placeholder rounded-square mark
  generated by `Tools/generate_icon.swift` (run it again to refresh).

### Changed

- The Detect button shows a spinner while the upfront OCR scan is in
  flight, not just while detection is running, so the editor never
  silently waits on Vision.

### Privacy

- All detection runs **on-device** via Apple's Vision and
  NaturalLanguage frameworks. No image or text leaves the machine.
- Place names, organisation names, dates, and URLs are intentionally
  **not** in the default mask set — they are usually not private and
  masking them by default would be noisy.

[0.3.0]: https://github.com/snaka/Bokashi/releases/tag/v0.3.0

## [0.2.0] - 2026-05-04

### Added

- **Mosaic annotation tool** — drag a rectangle with the new Mosaic
  tool to pixelate a region. The mosaic is treated like any other
  annotation: it participates in undo/redo and bakes into the
  rendered image at native resolution. Block size is fixed at 16
  image-pixels for this release.

### Changed

- The editor window now opens at the captured image's native point
  size, clamped to 80 % of the visible frame in either axis. Region
  and window captures stay 1:1; full-screen captures get a more
  generous initial window than the previous 2/3 cap.

[0.2.0]: https://github.com/snaka/Bokashi/releases/tag/v0.2.0

## [0.1.0] - 2026-05-04

First public release.

### Added

- Menubar app with global hotkeys (built on top of
  [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts)).
- Three capture modes:
  - **Full screen** — default hotkey `⌃⌥⇧4`.
  - **Window** — menu picker that lists currently shareable application
    windows and snapshots the chosen one at native resolution.
  - **Region** — drag-to-select transparent overlay, default hotkey `⌃⌥⇧6`.
- Editor window opens after every capture; nothing is written to disk
  unless the user explicitly saves.
  - **Copy & Close** (default action, `⌘W` / red close button) copies the
    annotated image to the clipboard.
  - **Save…** (`⌘S`) opens an `NSSavePanel`; on confirm, writes a PNG and
    posts a banner notification with Reveal-in-Finder.
  - **Discard** (`Esc`) drops the capture.
- Annotation tools:
  - Arrow, box (filled / outlined), ellipse (filled / outlined), line.
  - Eight color presets (red / orange / yellow / green / blue / purple /
    near-black / near-white).
  - Three stroke-width presets: thin / medium / thick.
- Undo / redo via the window's `UndoManager` (`⌘Z` / `⌘⇧Z`).

### Notes

- Distributed as **ad-hoc signed** zip from GitHub Releases. macOS
  Gatekeeper will warn on first launch; right-click → Open (or System
  Settings → Privacy & Security → Open Anyway) gets past it.

[0.1.0]: https://github.com/snaka/Bokashi/releases/tag/v0.1.0
