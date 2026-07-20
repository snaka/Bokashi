# Apple Intelligence sensitive-info detector (replacing the Ollama detector)

Date: 2026-07-19
Status: approved (design), pending implementation plan

## Context

Bokashi's auto-mask pipeline has two detectors: the always-on OCR/regex/NLTagger
path and an optional local vision-LLM path via Ollama (added in v0.5.0, PR #22).
The Ollama detector sends the full screenshot to a local vision model
(`llama3.2-vision` etc.) and asks it to return normalized bounding boxes of PII.
In practice the feature is effectively unusable: it requires installing and
configuring Ollama plus pulling a multi-GB model, inference takes tens of
seconds, and vision LLMs are weak at exactly the thing the prompt demands —
coordinate localization.

Apple's Foundation Models framework (macOS 26+) provides a free, on-device,
zero-setup LLM. This design replaces the Ollama detector with it, restructured
so the LLM never guesses coordinates: **the LLM judges which strings are
sensitive; rectangles come from Vision** (OCR bounding boxes and face
detection).

Decisions made with the maintainer (2026-07-19):

1. **Delete the Ollama detector outright** (code, settings UI, UserDefaults
   keys). No coexistence.
2. **Add a Vision face detector** to cover the "profile avatars" case the
   Ollama prompt handled, since a text LLM cannot see images. Works on all
   supported Macs, no Apple Intelligence required.
3. **Raise the deployment target from macOS 14.0 to macOS 26.0.**

## Measured feasibility (maintainer's M-series Mac, macOS 26.5.2)

A standalone benchmark (guided generation over 10 mixed ja/en OCR-style lines):

- `SystemLanguageModel.default.availability` → `.available`; no entitlement,
  no network, no setup.
- Warm latency 1.7–2.4 s per ~10-line batch (cold ~3.6 s). Ollama vision
  models take tens of seconds for the same screenshot.
- Correctly found items the deterministic detectors cannot: `@taro_yam`
  (handle), `sk-proj-…` (API key), plus emails/phones/addresses.
- Observed small-model quirks that the design must absorb:
  - An `other` catch-all category attracts false positives (dates, "OK",
    "Cancel"). → Do not offer `other`; drop any finding outside the fixed
    category list.
  - Returned substrings are sometimes a whole line rather than the minimal
    span, and occasionally not verbatim. → Re-locate every returned string in
    the source lines ourselves; never trust model-supplied offsets.
  - Line indices are occasionally off by one. → Treat `lineIndex` as a hint;
    fall back to searching all lines.
  - Recall varies run-to-run for names/addresses. → Acceptable: the
    deterministic detectors still cover those categories everywhere; the LLM
    is an additive layer.

## Constraints (from research, as of mid-2026)

- Foundation Models requires macOS 26+, Apple Silicon, and Apple Intelligence
  enabled. macOS 26 still installs on some Intel Macs, so
  `.unavailable(.deviceNotEligible)`, `.appleIntelligenceNotEnabled`, and
  `.modelNotReady` are all reachable at runtime even after the target bump.
  The detector must degrade silently and Settings must show why.
- On-device context window is 4,096 tokens shared between input and output;
  Japanese costs ~1 token per character. OCR lines must be chunked.
- Credential-heavy text can trip the framework's safety guardrails
  (`guardrailViolation`). Chunk-level error isolation keeps one refused chunk
  from killing the whole detection pass.
- Japanese is a supported Apple Intelligence language.
- Multimodal (image) input exists only on the OS-27 / AFM-3-Advanced line with
  an unclear device matrix; out of scope. Noted as a future option for
  avatar-precision work.

## Architecture

`SensitiveRegionDetector` (BokashiCore) is unchanged — it remains the seam.
Detector lineup after this change:

| Detector | identifier | Coverage | Runs when |
|---|---|---|---|
| `OCRSensitiveRegionDetector` (existing) | `ocr` | emails (regex), phones/addresses (NSDataDetector), names (NLTagger), custom terms | always |
| `AppleIntelligenceSensitiveRegionDetector` (new) | `appleIntelligence` | contextual text PII: usernames/handles, API keys/tokens, credit cards, names the tagger misses | toggle ON and model `.available` |
| `FaceSensitiveRegionDetector` (new) | `face` | faces / profile avatars | toggle ON |

`OllamaSensitiveRegionDetector`, `OllamaDetectorSettings`,
`OllamaConnectionTester`, and the Ollama settings UI are deleted.

### Data flow (AI detector)

1. Editor already runs `OCRRunner.recognize` → `[TextObservation]` (text +
   per-substring pixel rects). The AI detector receives these observations at
   init, same pattern as `OCRSensitiveRegionDetector`.
2. `LineBatcher` (BokashiCore) splits the observation texts into chunks under a
   character budget (~1,500 chars, safe for a 4,096-token window with
   Japanese) while never splitting a line.
3. Per chunk, a fresh `LanguageModelSession` (same instructions each time —
   fresh sessions keep the transcript from accumulating toward the 4,096-token
   window) with one `respond(to:generating:)` call and a `@Generable` result
   type: `[{lineIndex: Int, text: String, category}]`, category constrained
   via `Guide(.anyOf(...))` to
   `personalName / username / email / phoneNumber / address / apiKey /
   creditCard` — deliberately no `other`.
4. `FindingLocator` (BokashiCore) resolves each finding to `(observation,
   NSRange)`: verify `text` occurs verbatim in the hinted line; otherwise
   search all lines; unresolvable findings are dropped. The resolved range maps
   to pixels via the existing `TextObservation.imageRect(forSubrange:)`.
5. Errors (guardrail refusal, context overflow, cancellation) are caught per
   chunk; the chunk contributes nothing and the pass continues — matching the
   protocol's "fail silently with an empty array" contract.
6. When the editor window opens (and the detector is enabled + available), a
   session is created and `prewarm()`ed once to page the model in, so the
   first Detect click doesn't pay the cold start; the per-chunk sessions then
   reuse the already-loaded model.

### Face detector

`VNDetectFaceRectanglesRequest` over the full image; each face rect is padded
by 10% of its own size on every side (tunable constant — face rects hug the
face while avatars are usually a larger circle) and emitted as
`DetectedRegion(label: "face")`. Deterministic, fast, macOS 14-era API, no
Apple Intelligence dependency. It will mask any face (news photos as well as
avatars); masks are ordinary annotations the user can erase individually, and
the detector has its own Settings toggle.

### Orchestration and dedup

`AutoMasker.detect` builds the detector list: OCR always; face if enabled;
Apple Intelligence if enabled and `SystemLanguageModel.default.availability ==
.available`. Because the OCR and AI detectors can both flag the same string
(e.g. an email), a `RegionDeduplicator` (BokashiCore) merges near-duplicate
rects before annotations are created: a region is dropped if it overlaps an
already-kept region with IoU ≥ 0.6 (tunable constant) or is contained by it;
deterministic-detector regions win over AI regions on ties. Face regions
rarely collide with text regions and pass through the same dedup unchanged.

## Settings

`DetectorsSettingsView` replaces the Ollama section with:

- **Apple Intelligence** section: "Use Apple Intelligence detection" toggle
  (default ON) plus a status row derived from
  `SystemLanguageModel.default.availability`:
  - available → "Ready"
  - `.appleIntelligenceNotEnabled` → hint to enable it in System Settings
  - `.modelNotReady` → "Model is downloading — try again later"
  - `.deviceNotEligible` → "Not supported on this Mac"
  The toggle stays visible but the detector only runs when available.
- **Faces** : "Mask faces and avatars" toggle (default ON).
- Developer section unchanged except color mapping: blue = OCR, orange =
  Apple Intelligence, green = face.

New persistence: `DetectionSettings` (`@Observable`, UserDefaults-backed,
same pattern as the deleted `OllamaDetectorSettings`) with keys
`BokashiAIDetectorEnabled`, `BokashiFaceDetectorEnabled` (both default true). On launch, the three obsolete Ollama keys
(`BokashiOllamaDetectorEnabled` / `Endpoint` / `Model`) are removed.

## Project / docs changes

- `project.yml`: `deploymentTarget` and `MACOSX_DEPLOYMENT_TARGET` → `26.0`.
- `Packages/BokashiCore/Package.swift` stays at `.macOS(.v14)` — the new core
  logic is pure Swift with no FoundationModels dependency, and keeping the
  floor low keeps the package honest about what it needs.
- `CLAUDE.md`: deployment-target note (14.0 → 26.0) and the "local vision
  LLMs" phrasing in this seam's doc comment if touched.
- `docs/ROADMAP.md`: Detection backlog — remove/replace the CoreML-model-pack
  line's implicit Ollama context; record that the LLM layer is now Apple
  Foundation Models.
- `CHANGELOG.md`: not touched on the feature branch; the v0.9.0 release-prep
  PR writes the section (Added: Apple Intelligence + face detectors; Removed:
  Ollama detector; Changed: **breaking** — requires macOS 26).
- `README.md` has no Ollama references; verify at implementation time.

## Testing

- BokashiCore unit tests (`swift test`): `LineBatcher` (budget respected,
  no line split, order preserved), `FindingLocator` (verbatim hit on hinted
  line, off-by-one recovery, cross-line search, whole-line finding, no-match
  drop, duplicate findings), `RegionDeduplicator` (IoU merge, containment,
  deterministic-wins tie-break).
- The FoundationModels call itself stays thin (no app-host test); the
  benchmark scripts from the feasibility run are kept as a manual tuning
  harness (scratchpad, not committed).
- End-to-end: build the app, capture a screenshot containing a handle, an API
  key, an email, and a face; run Detect; confirm masks land, dev-mode colors
  distinguish sources, and disabling each toggle removes its contribution.
- Regression: with Apple Intelligence unavailable (e.g. toggled off in System
  Settings), Detect still produces OCR-detector results with no error UI.

## Out of scope / future

- Multimodal Foundation Models input (`Attachment`) for direct avatar
  detection — revisit when the OS-27 device matrix is clear.
- Migrating `OCRRunner` to the macOS 15+ `RecognizeTextRequest` Swift API —
  orthogonal modernization.
- Reviewable detection candidates (preview before applying) — already on the
  roadmap backlog, unchanged by this design.
