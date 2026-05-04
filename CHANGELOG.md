# Changelog

All notable changes to Bokashi are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
