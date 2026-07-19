# Apple Intelligence Detector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Ollama local-LLM detector with an on-device Apple Foundation Models text detector plus a Vision face detector, and raise the deployment target to macOS 26.

**Architecture:** The LLM never guesses coordinates. Vision OCR (existing `OCRRunner`) supplies per-substring pixel rects; the Foundation Models on-device LLM only classifies which OCR strings are sensitive; a Vision face detector covers avatars. Pure logic (batching, substring re-location, rect dedup) lives in `BokashiCore` with unit tests and no FoundationModels dependency; the two new detectors conform to the existing `SensitiveRegionDetector` protocol in the app target.

**Tech Stack:** Swift 5.10 mode / Xcode 26, SwiftUI, FoundationModels (`LanguageModelSession`, `@Generable`), Vision (`VNDetectFaceRectanglesRequest`), XcodeGen, XCTest via SPM.

**Spec:** `docs/superpowers/specs/2026-07-19-apple-intelligence-detector-design.md`

## Global Constraints

- Deployment target: macOS **26.0** (raised from 14.0 in Task 4; Tasks 1–3 build against the unchanged project).
- `Packages/BokashiCore` stays at `.macOS(.v14)` and must NOT import FoundationModels or Vision.
- No new third-party dependencies.
- UI strings are English, hard-coded (repo has no localization catalog).
- No code comments unless the *why* is non-obvious; no emojis in code or commits.
- Every commit message ends with the two-line trailer:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_015LjHn51hSiDpVecFzkTHa1`
- Work happens on the existing branch `feat/apple-intelligence-detector`.
- Commands run from the repo root `/Users/snaka/ghq/github.com/snaka/Bokashi`.
- Core test command: `swift test --package-path Packages/BokashiCore`
- App build command: `xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO` (run `xcodegen` first whenever `project.yml` changed or app-target files were added/removed).

---

### Task 1: LineBatcher (BokashiCore)

Chunks OCR lines into prompt-sized batches so a single Foundation Models call stays far below the 4,096-token shared context window (Japanese ≈ 1 token/char). Never splits a line; skips blank lines; preserves global line indices, which the prompt and `FindingLocator` both use.

**Files:**
- Create: `Packages/BokashiCore/Sources/BokashiCore/Detection/LineBatcher.swift`
- Test: `Packages/BokashiCore/Tests/BokashiCoreTests/LineBatcherTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `public struct IndexedLine { let index: Int; let text: String }` and `LineBatcher.batches(from: [String], characterBudget: Int) -> [[IndexedLine]]` — used by Task 6.

- [ ] **Step 1: Write the failing tests**

```swift
// Packages/BokashiCore/Tests/BokashiCoreTests/LineBatcherTests.swift
import XCTest
@testable import BokashiCore

final class LineBatcherTests: XCTestCase {
    func testSingleBatchWhenUnderBudget() {
        let batches = LineBatcher.batches(from: ["one", "two", "three"], characterBudget: 200)
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches[0].map(\.text), ["one", "two", "three"])
        XCTAssertEqual(batches[0].map(\.index), [0, 1, 2])
    }

    func testSplitsWhenBudgetExceeded() {
        // Each line costs 10 (text) + 8 (per-line overhead) = 18; budget 40 fits two.
        let lines = ["aaaaaaaaaa", "bbbbbbbbbb", "cccccccccc", "dddddddddd"]
        let batches = LineBatcher.batches(from: lines, characterBudget: 40)
        XCTAssertEqual(batches.count, 2)
        XCTAssertEqual(batches[0].map(\.index), [0, 1])
        XCTAssertEqual(batches[1].map(\.index), [2, 3])
    }

    func testNeverSplitsASingleLongLine() {
        let long = String(repeating: "x", count: 500)
        let batches = LineBatcher.batches(from: ["short", long, "tail"], characterBudget: 100)
        XCTAssertEqual(batches.count, 3)
        XCTAssertEqual(batches[1].map(\.text), [long])
        XCTAssertEqual(batches[1].map(\.index), [1])
    }

    func testSkipsBlankLinesButKeepsGlobalIndices() {
        let batches = LineBatcher.batches(from: ["a", "", "   ", "b"], characterBudget: 200)
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches[0].map(\.index), [0, 3])
        XCTAssertEqual(batches[0].map(\.text), ["a", "b"])
    }

    func testEmptyInputYieldsNoBatches() {
        XCTAssertTrue(LineBatcher.batches(from: [], characterBudget: 100).isEmpty)
        XCTAssertTrue(LineBatcher.batches(from: ["", "  "], characterBudget: 100).isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/BokashiCore --filter LineBatcherTests`
Expected: compile FAILURE — `cannot find 'LineBatcher' in scope`.

- [ ] **Step 3: Write the implementation**

```swift
// Packages/BokashiCore/Sources/BokashiCore/Detection/LineBatcher.swift
import Foundation

public struct IndexedLine: Hashable, Sendable {
    public let index: Int
    public let text: String

    public init(index: Int, text: String) {
        self.index = index
        self.text = text
    }
}

/// Splits OCR lines into batches that each fit a per-request character
/// budget. The on-device Foundation Models context window is 4,096 tokens
/// shared between input and output, and Japanese costs roughly one token
/// per character, so callers pass a budget well below that. Lines are
/// never split; a line longer than the budget gets a batch of its own.
public enum LineBatcher {
    /// Accounts for the "<index>: " prefix and newline each line costs
    /// in the numbered prompt.
    private static let perLineOverhead = 8

    public static func batches(
        from lines: [String],
        characterBudget: Int
    ) -> [[IndexedLine]] {
        var result: [[IndexedLine]] = []
        var current: [IndexedLine] = []
        var currentCost = 0
        for (index, text) in lines.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let cost = text.count + Self.perLineOverhead
            if !current.isEmpty, currentCost + cost > characterBudget {
                result.append(current)
                current = []
                currentCost = 0
            }
            current.append(IndexedLine(index: index, text: text))
            currentCost += cost
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/BokashiCore --filter LineBatcherTests`
Expected: `Executed 5 tests, with 0 failures`.

- [ ] **Step 5: Run the full package suite (no regressions)**

Run: `swift test --package-path Packages/BokashiCore`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add Packages/BokashiCore/Sources/BokashiCore/Detection/LineBatcher.swift \
        Packages/BokashiCore/Tests/BokashiCoreTests/LineBatcherTests.swift
git commit -m "feat: add LineBatcher for chunking OCR lines under a prompt budget"
```

---

### Task 2: FindingLocator (BokashiCore)

Re-locates a model-reported substring in the source OCR lines. The on-device model was observed (2026-07-19 benchmark) to occasionally report an off-by-one line index, return a whole line instead of the minimal span, or change case — so the locator treats the index as a hint, tries neighbors, then searches all lines, case-insensitively.

**Files:**
- Create: `Packages/BokashiCore/Sources/BokashiCore/Detection/FindingLocator.swift`
- Test: `Packages/BokashiCore/Tests/BokashiCoreTests/FindingLocatorTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `FindingLocator.Located { lineIndex: Int; nsRange: NSRange }` and `FindingLocator.locate(text: String, hintIndex: Int?, in lines: [String]) -> Located?` — used by Task 6. The `NSRange` is UTF-16 based, compatible with `OCRRunner.TextObservation.imageRect(forSubrange:)`.

- [ ] **Step 1: Write the failing tests**

```swift
// Packages/BokashiCore/Tests/BokashiCoreTests/FindingLocatorTests.swift
import XCTest
@testable import BokashiCore

final class FindingLocatorTests: XCTestCase {
    let lines = [
        "Dashboard",
        "Signed in as @taro_yam",
        "電話: 090-1234-5678",
        "Contact: alice@example.com now",
    ]

    func testFindsVerbatimTextOnHintedLine() {
        let located = FindingLocator.locate(text: "@taro_yam", hintIndex: 1, in: lines)
        XCTAssertEqual(located?.lineIndex, 1)
        XCTAssertEqual(located?.nsRange, NSRange(location: 13, length: 9))
    }

    func testRecoversFromOffByOneHint() {
        let located = FindingLocator.locate(text: "@taro_yam", hintIndex: 2, in: lines)
        XCTAssertEqual(located?.lineIndex, 1)
    }

    func testFallsBackToSearchingAllLines() {
        let located = FindingLocator.locate(text: "alice@example.com", hintIndex: 0, in: lines)
        XCTAssertEqual(located?.lineIndex, 3)
    }

    func testNilHintSearchesAllLines() {
        let located = FindingLocator.locate(text: "090-1234-5678", hintIndex: nil, in: lines)
        XCTAssertEqual(located?.lineIndex, 2)
    }

    func testJapaneseSubstringRangeIsUTF16() {
        let located = FindingLocator.locate(text: "090-1234-5678", hintIndex: 2, in: lines)
        // "電話: " is 4 UTF-16 units (電, 話, :, space).
        XCTAssertEqual(located?.nsRange, NSRange(location: 4, length: 13))
    }

    func testMatchesCaseInsensitively() {
        let located = FindingLocator.locate(text: "ALICE@EXAMPLE.COM", hintIndex: 3, in: lines)
        XCTAssertEqual(located?.lineIndex, 3)
        XCTAssertEqual(located?.nsRange, NSRange(location: 9, length: 17))
    }

    func testTrimsWhitespaceFromFinding() {
        let located = FindingLocator.locate(text: "  @taro_yam \n", hintIndex: 1, in: lines)
        XCTAssertEqual(located?.nsRange, NSRange(location: 13, length: 9))
    }

    func testReturnsNilWhenTextNowhere() {
        XCTAssertNil(FindingLocator.locate(text: "not-in-any-line", hintIndex: 1, in: lines))
        XCTAssertNil(FindingLocator.locate(text: "   ", hintIndex: 1, in: lines))
        XCTAssertNil(FindingLocator.locate(text: "Dashboard", hintIndex: 0, in: []))
    }

    func testOutOfBoundsHintStillSearches() {
        let located = FindingLocator.locate(text: "@taro_yam", hintIndex: 99, in: lines)
        XCTAssertEqual(located?.lineIndex, 1)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/BokashiCore --filter FindingLocatorTests`
Expected: compile FAILURE — `cannot find 'FindingLocator' in scope`.

- [ ] **Step 3: Write the implementation**

```swift
// Packages/BokashiCore/Sources/BokashiCore/Detection/FindingLocator.swift
import Foundation

/// Resolves a substring reported by the on-device language model back to a
/// verbatim UTF-16 range in the source OCR lines. The model's line index is
/// only a hint — small models are occasionally off by one — so the hinted
/// line and its neighbors are tried first, then every line in order. Matching
/// is case-insensitive because the model sometimes normalizes case.
public enum FindingLocator {
    public struct Located: Hashable, Sendable {
        public let lineIndex: Int
        public let nsRange: NSRange

        public init(lineIndex: Int, nsRange: NSRange) {
            self.lineIndex = lineIndex
            self.nsRange = nsRange
        }
    }

    public static func locate(
        text: String,
        hintIndex: Int?,
        in lines: [String]
    ) -> Located? {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty, !lines.isEmpty else { return nil }

        var order: [Int] = []
        if let hint = hintIndex {
            for candidate in [hint, hint - 1, hint + 1]
            where lines.indices.contains(candidate) && !order.contains(candidate) {
                order.append(candidate)
            }
        }
        for index in lines.indices where !order.contains(index) {
            order.append(index)
        }

        for index in order {
            let nsLine = lines[index] as NSString
            let range = nsLine.range(of: needle, options: .caseInsensitive)
            if range.location != NSNotFound {
                return Located(lineIndex: index, nsRange: range)
            }
        }
        return nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/BokashiCore --filter FindingLocatorTests`
Expected: `Executed 9 tests, with 0 failures`.

- [ ] **Step 5: Commit**

```bash
git add Packages/BokashiCore/Sources/BokashiCore/Detection/FindingLocator.swift \
        Packages/BokashiCore/Tests/BokashiCoreTests/FindingLocatorTests.swift
git commit -m "feat: add FindingLocator to resolve model findings to OCR line ranges"
```

---

### Task 3: RegionDeduplicator (BokashiCore)

The OCR detector and the AI detector can both flag the same string (an email matches the regex *and* the model). Dedup keeps the first occurrence — callers order deterministic detectors first — and drops later regions that overlap a kept one at IoU ≥ 0.6 or sit inside it.

**Files:**
- Create: `Packages/BokashiCore/Sources/BokashiCore/Detection/RegionDeduplicator.swift`
- Test: `Packages/BokashiCore/Tests/BokashiCoreTests/RegionDeduplicatorTests.swift`

**Interfaces:**
- Consumes: `DetectedRegion` (existing, `SensitiveRegionDetector.swift`).
- Produces: `RegionDeduplicator.keptIndices(of: [DetectedRegion], iouThreshold: Double = 0.6) -> [Int]` (ascending original indices) — used by Task 7.

- [ ] **Step 1: Write the failing tests**

```swift
// Packages/BokashiCore/Tests/BokashiCoreTests/RegionDeduplicatorTests.swift
import XCTest
@testable import BokashiCore

final class RegionDeduplicatorTests: XCTestCase {
    private func region(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                        label: String = "test") -> DetectedRegion {
        DetectedRegion(rect: CGRect(x: x, y: y, width: w, height: h), label: label)
    }

    func testKeepsDisjointRegions() {
        let regions = [region(0, 0, 10, 10), region(100, 100, 10, 10)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0, 1])
    }

    func testDropsNearIdenticalDuplicate() {
        // Second rect shifted by 1px on a 100x20 rect: IoU ≈ 0.9.
        let regions = [region(10, 10, 100, 20), region(11, 10, 100, 20)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0])
    }

    func testDropsContainedRegion() {
        // Small rect inside a big one has low IoU but should still be dropped.
        let regions = [region(0, 0, 200, 100), region(50, 40, 20, 10)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0])
    }

    func testKeepsPartialOverlapBelowThreshold() {
        // Half-width overlap on equal rects: IoU = 1/3 < 0.6.
        let regions = [region(0, 0, 100, 20), region(50, 0, 100, 20)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0, 1])
    }

    func testEarlierRegionWins() {
        // Order encodes priority; the caller lists deterministic detectors first.
        let regions = [region(0, 0, 100, 20, label: "email"),
                       region(0, 0, 100, 20, label: "aiEmail")]
        let kept = RegionDeduplicator.keptIndices(of: regions)
        XCTAssertEqual(kept, [0])
        XCTAssertEqual(regions[kept[0]].label, "email")
    }

    func testDropsEmptyRects() {
        let regions = [region(0, 0, 0, 0), region(5, 5, 10, 10)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [1])
    }

    func testEmptyInput() {
        XCTAssertTrue(RegionDeduplicator.keptIndices(of: []).isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/BokashiCore --filter RegionDeduplicatorTests`
Expected: compile FAILURE — `cannot find 'RegionDeduplicator' in scope`.

- [ ] **Step 3: Write the implementation**

```swift
// Packages/BokashiCore/Sources/BokashiCore/Detection/RegionDeduplicator.swift
import CoreGraphics

/// Drops regions that duplicate an earlier region — either near-identical
/// (IoU at or above the threshold) or fully contained. Order encodes
/// priority: callers list deterministic detectors before AI ones so the
/// precise, reproducible rect survives a conflict.
public enum RegionDeduplicator {
    public static func keptIndices(
        of regions: [DetectedRegion],
        iouThreshold: Double = 0.6
    ) -> [Int] {
        var kept: [Int] = []
        outer: for (index, region) in regions.enumerated() {
            let rect = region.rect
            guard !rect.isNull, rect.width > 0, rect.height > 0 else { continue }
            for keptIndex in kept {
                let keptRect = regions[keptIndex].rect
                if keptRect.contains(rect) { continue outer }
                if iou(keptRect, rect) >= iouThreshold { continue outer }
            }
            kept.append(index)
        }
        return kept
    }

    private static func iou(_ a: CGRect, _ b: CGRect) -> Double {
        let intersection = a.intersection(b)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else {
            return 0
        }
        let intersectionArea = Double(intersection.width * intersection.height)
        let unionArea = Double(a.width * a.height) + Double(b.width * b.height) - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/BokashiCore --filter RegionDeduplicatorTests`
Expected: `Executed 7 tests, with 0 failures`.

- [ ] **Step 5: Run the full package suite and commit**

Run: `swift test --package-path Packages/BokashiCore`
Expected: all tests pass.

```bash
git add Packages/BokashiCore/Sources/BokashiCore/Detection/RegionDeduplicator.swift \
        Packages/BokashiCore/Tests/BokashiCoreTests/RegionDeduplicatorTests.swift
git commit -m "feat: add RegionDeduplicator for cross-detector mask dedup"
```

---

### Task 4: Raise deployment target to macOS 26

Prerequisite for importing FoundationModels without availability annotations. Approved as a breaking change (spec, decision 3); the v0.9.0 release notes will flag it. `CLAUDE.md` documents the target, so it changes in the same commit.

**Files:**
- Modify: `project.yml:4-5` and `project.yml:12`
- Modify: `CLAUDE.md` (deployment-target bullet, "Stack and conventions" section)

**Interfaces:**
- Consumes: nothing.
- Produces: a project whose app target compiles `import FoundationModels` unconditionally — required by Tasks 6–8.

- [ ] **Step 1: Edit `project.yml`**

Change line 5 from `    macOS: "14.0"` to `    macOS: "26.0"` and line 12 from `    MACOSX_DEPLOYMENT_TARGET: "14.0"` to `    MACOSX_DEPLOYMENT_TARGET: "26.0"`. Both values live under `options.deploymentTarget` and `settings.base` respectively; touch nothing else.

- [ ] **Step 2: Edit `CLAUDE.md`**

Replace the bullet:

```markdown
- **Deployment target:** macOS 14.0+. Do not introduce APIs that require
  newer versions without discussion.
```

with:

```markdown
- **Deployment target:** macOS 26.0+ (raised from 14.0 in 2026-07 for the
  Foundation Models framework). Apple Intelligence availability must still
  be checked at runtime — macOS 26 runs on some Intel Macs and users can
  keep Apple Intelligence off.
```

- [ ] **Step 3: Regenerate and build**

Run: `xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO`
Expected: `BUILD SUCCEEDED`. If the macOS 26 minimum surfaces new deprecation warnings for `VNRecognizeTextRequest`/Vision classes, leave them — migrating to the new Vision Swift API is explicitly out of scope (spec).

- [ ] **Step 4: Commit**

```bash
git add project.yml CLAUDE.md
git commit -m "chore: raise deployment target to macOS 26"
```

---### Task 5: FaceSensitiveRegionDetector

Covers the "profile avatars" case the deleted Ollama prompt handled — a text LLM cannot see images. Deterministic, fast, no Apple Intelligence dependency. Mirrors `OCRRunner`'s continuation + coordinate-flip idiom (Vision returns normalized bottom-left-origin rects; annotations use top-left pixel rects).

**Files:**
- Create: `Bokashi/Detection/FaceSensitiveRegionDetector.swift`

**Interfaces:**
- Consumes: `SensitiveRegionDetector`, `DetectedRegion` (BokashiCore).
- Produces: `FaceSensitiveRegionDetector()` with `identifier == "face"`, emitting `DetectedRegion(label: "face")` — used by Tasks 7–8.

- [ ] **Step 1: Write the implementation**

```swift
// Bokashi/Detection/FaceSensitiveRegionDetector.swift
import BokashiCore
import CoreGraphics
import Vision

@MainActor
struct FaceSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "face"

    /// Face rects hug the face itself while avatars are usually a larger
    /// circle, so each side is padded by this fraction of the rect's size.
    private static let padding: CGFloat = 0.1

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        let imageSize = CGSize(width: image.width, height: image.height)
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let results = (request.results as? [VNFaceObservation]) ?? []
                let bounds = CGRect(origin: .zero, size: imageSize)
                let regions = results.compactMap { observation -> DetectedRegion? in
                    let normalized = observation.boundingBox
                    let width = normalized.width * imageSize.width
                    let height = normalized.height * imageSize.height
                    let x = normalized.origin.x * imageSize.width
                    let yTopLeft = imageSize.height
                        - normalized.origin.y * imageSize.height
                        - height
                    let padded = CGRect(x: x, y: yTopLeft, width: width, height: height)
                        .insetBy(dx: -width * Self.padding, dy: -height * Self.padding)
                        .intersection(bounds)
                    guard !padded.isNull, padded.width >= 4, padded.height >= 4 else {
                        return nil
                    }
                    return DetectedRegion(rect: padded.integral, label: "face")
                }
                continuation.resume(returning: regions)
            }
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Regenerate and build**

Run: `xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO`
Expected: `BUILD SUCCEEDED` (the type is not referenced yet; Task 7 wires it in).

- [ ] **Step 3: Commit**

```bash
git add Bokashi/Detection/FaceSensitiveRegionDetector.swift
git commit -m "feat: add Vision face detector for masking faces and avatars"
```

---

### Task 6: AppleIntelligenceSensitiveRegionDetector

The Foundation Models detector. Feasibility and the prompt/schema shape were validated by a live benchmark on the maintainer's Mac (2026-07-19): warm latency 1.7–2.4 s per ~10-line batch; correct detection of handles and API keys; category list deliberately has **no `other`** (it attracted false positives — dates, "OK", "Cancel"); substrings are re-located with `FindingLocator`, never trusted.

**Files:**
- Create: `Bokashi/Detection/AppleIntelligenceSensitiveRegionDetector.swift`

**Interfaces:**
- Consumes: `LineBatcher.batches(from:characterBudget:)` (Task 1), `FindingLocator.locate(text:hintIndex:in:)` (Task 2), `OCRRunner.TextObservation` (existing: `.text`, `.imageRect(forSubrange:)`), `SensitiveRegionDetector` / `DetectedRegion` (existing).
- Produces: `AppleIntelligenceSensitiveRegionDetector(observations:)` with `identifier == "appleIntelligence"`; `static var isModelAvailable: Bool`; `static func prewarmIfNeeded()` — used by Tasks 7–8. Region labels are the category strings (`personalName`, `username`, `email`, `phoneNumber`, `address`, `apiKey`, `creditCard`).

- [ ] **Step 1: Write the implementation**

```swift
// Bokashi/Detection/AppleIntelligenceSensitiveRegionDetector.swift
import BokashiCore
import CoreGraphics
import Foundation
import FoundationModels

@Generable
private struct AIFinding {
    @Guide(description: "Index of the line containing the sensitive text")
    var lineIndex: Int
    @Guide(description: "The exact sensitive substring copied verbatim from the line, nothing more")
    var text: String
    @Guide(
        description: "Category of the sensitive item",
        .anyOf([
            "personalName", "username", "email", "phoneNumber",
            "address", "apiKey", "creditCard",
        ])
    )
    var category: String
}

@Generable
private struct AIFindings {
    var findings: [AIFinding]
}

@MainActor
struct AppleIntelligenceSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "appleIntelligence"

    let observations: [OCRRunner.TextObservation]

    /// Stays well under the 4,096-token shared context window even for
    /// all-Japanese text (~1 token per character).
    private static let characterBudget = 1500

    private static let instructions = """
        You review OCR text lines extracted from a screenshot and identify \
        sensitive personal information that should be masked before the \
        screenshot is shared: personal names, usernames and account handles, \
        email addresses, phone numbers, physical addresses, API keys, access \
        tokens and other secrets, and credit card numbers. Report each \
        sensitive item with the index of the line it appears on and the exact \
        substring copied verbatim from that line, only the sensitive part, \
        not the surrounding text. Ignore generic UI text, dates, prices, and \
        button labels. If nothing is sensitive, return an empty findings array.
        """

    static var isModelAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    /// Pages the on-device model in ahead of the first Detect click.
    /// (Task 8 adds a DetectionSettings gate once that type exists.)
    static func prewarmIfNeeded() {
        guard isModelAvailable else { return }
        LanguageModelSession(instructions: instructions).prewarm()
    }

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        guard Self.isModelAvailable, !observations.isEmpty else { return [] }

        let lines = observations.map(\.text)
        var regions: [DetectedRegion] = []

        for batch in LineBatcher.batches(from: lines, characterBudget: Self.characterBudget) {
            let numbered = batch
                .map { "\($0.index): \($0.text)" }
                .joined(separator: "\n")

            // A fresh session per batch keeps the transcript from
            // accumulating toward the context window; failures (safety
            // guardrails, overflow) cost only this batch.
            let session = LanguageModelSession(instructions: Self.instructions)
            let findings: [AIFinding]
            do {
                let response = try await session.respond(
                    to: "Lines:\n\(numbered)",
                    generating: AIFindings.self
                )
                findings = response.content.findings
            } catch {
                continue
            }

            for finding in findings {
                guard
                    let located = FindingLocator.locate(
                        text: finding.text,
                        hintIndex: finding.lineIndex,
                        in: lines
                    ),
                    let rect = observations[located.lineIndex]
                        .imageRect(forSubrange: located.nsRange)
                else { continue }
                regions.append(
                    DetectedRegion(
                        rect: rect.insetBy(dx: -2, dy: -2),
                        label: finding.category
                    )
                )
            }
        }
        return regions
    }
}
```

Note: `prewarmIfNeeded()` deliberately has no settings check yet — `DetectionSettings` arrives in Task 7, and Task 8 Step 2 adds the `DetectionSettings.shared.aiDetectionEnabled` condition. As written above, the file compiles standalone.

- [ ] **Step 2: Regenerate and build**

Run: `xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add Bokashi/Detection/AppleIntelligenceSensitiveRegionDetector.swift
git commit -m "feat: add on-device Apple Intelligence sensitive-text detector"
```

---

### Task 7: DetectionSettings + AutoMasker rewiring

Introduces the new persisted toggles (both default ON — the detectors need zero setup) and swaps the Ollama detector out of the orchestration. Detector order is the dedup priority: OCR first, then face, then AI.

**Files:**
- Create: `Bokashi/Settings/DetectionSettings.swift`
- Modify: `Bokashi/Detection/AutoMasker.swift` (full body below)

**Interfaces:**
- Consumes: `FaceSensitiveRegionDetector` (Task 5), `AppleIntelligenceSensitiveRegionDetector` + `.isModelAvailable` (Task 6), `RegionDeduplicator.keptIndices(of:)` (Task 3).
- Produces: `DetectionSettings.shared` with `aiDetectionEnabled: Bool`, `faceMaskingEnabled: Bool`, `static func removeObsoleteOllamaDefaults()` — used by Task 8. `AutoMasker.detect` keeps its existing signature (`EditorState` needs no changes).

- [ ] **Step 1: Create `DetectionSettings`**

```swift
// Bokashi/Settings/DetectionSettings.swift
import Foundation

@MainActor
@Observable
final class DetectionSettings {
    static let shared = DetectionSettings()

    private static let aiEnabledKey = "BokashiAIDetectorEnabled"
    private static let faceEnabledKey = "BokashiFaceDetectorEnabled"

    var aiDetectionEnabled: Bool {
        didSet { UserDefaults.standard.set(aiDetectionEnabled, forKey: Self.aiEnabledKey) }
    }

    var faceMaskingEnabled: Bool {
        didSet { UserDefaults.standard.set(faceMaskingEnabled, forKey: Self.faceEnabledKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        aiDetectionEnabled = (defaults.object(forKey: Self.aiEnabledKey) as? Bool) ?? true
        faceMaskingEnabled = (defaults.object(forKey: Self.faceEnabledKey) as? Bool) ?? true
    }

    /// The Ollama detector shipped in v0.5.0 and was removed in favor of
    /// the Apple Intelligence detector; clear its orphaned defaults.
    static func removeObsoleteOllamaDefaults() {
        let defaults = UserDefaults.standard
        for key in [
            "BokashiOllamaDetectorEnabled",
            "BokashiOllamaDetectorEndpoint",
            "BokashiOllamaDetectorModel",
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}
```

- [ ] **Step 2: Rewrite `AutoMasker.swift`**

Replace the entire file content with:

```swift
// Bokashi/Detection/AutoMasker.swift
import BokashiCore
import CoreGraphics

@MainActor
enum AutoMasker {
    struct Detection {
        let annotation: Annotation
        let detectorIdentifier: String
    }

    static func detect(
        in image: CGImage,
        observations: [OCRRunner.TextObservation],
        customTerms: [String]
    ) async -> [Detection] {
        // Order is dedup priority: deterministic detectors first so their
        // precise rects win over near-duplicate AI findings.
        var detectors: [any SensitiveRegionDetector] = [
            OCRSensitiveRegionDetector(observations: observations, customTerms: customTerms)
        ]
        let settings = DetectionSettings.shared
        if settings.faceMaskingEnabled {
            detectors.append(FaceSensitiveRegionDetector())
        }
        if settings.aiDetectionEnabled, AppleIntelligenceSensitiveRegionDetector.isModelAvailable {
            detectors.append(AppleIntelligenceSensitiveRegionDetector(observations: observations))
        }

        var labeled: [(region: DetectedRegion, detectorIdentifier: String)] = []
        for detector in detectors {
            do {
                let regions = try await detector.detect(in: image)
                labeled.append(contentsOf: regions.map { ($0, detector.identifier) })
            } catch {
                continue
            }
        }

        let kept = RegionDeduplicator.keptIndices(of: labeled.map(\.region))
        return kept.map { index in
            Detection(
                annotation: Annotation(
                    kind: .mosaic(rect: labeled[index].region.rect),
                    style: .defaultOutline
                ),
                detectorIdentifier: labeled[index].detectorIdentifier
            )
        }
    }
}
```

- [ ] **Step 3: Regenerate and build**

Run: `xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO`
Expected: `BUILD SUCCEEDED`. (`OllamaSensitiveRegionDetector` and `OllamaDetectorSettings` still exist and compile; they are now unused by AutoMasker and get deleted in Task 9.)

- [ ] **Step 4: Commit**

```bash
git add Bokashi/Settings/DetectionSettings.swift Bokashi/Detection/AutoMasker.swift
git commit -m "feat: wire face and Apple Intelligence detectors into AutoMasker"
```

---

### Task 8: Settings UI, prewarm, debug colors, launch cleanup

Replaces the Ollama settings section with the Apple Intelligence + face toggles and an availability status row; hooks model prewarm into editor-open; updates the developer color legend; clears obsolete defaults at launch.

**Files:**
- Modify: `Bokashi/Settings/DetectorsSettingsView.swift` (full replacement below)
- Modify: `Bokashi/Detection/AppleIntelligenceSensitiveRegionDetector.swift` (`prewarmIfNeeded` gains the settings check)
- Modify: `Bokashi/Editor/EditorWindowController.swift:59-67` (prewarm call)
- Modify: `Bokashi/Editor/AnnotationCanvas.swift:109-115` (`debugColor(for:)`)
- Modify: `Bokashi/AppDelegate.swift:20-24` (`applicationDidFinishLaunching`)

**Interfaces:**
- Consumes: `DetectionSettings` (Task 7), `AppleIntelligenceSensitiveRegionDetector.prewarmIfNeeded()` / `.isModelAvailable` (Task 6), `SystemLanguageModel.default.availability` (FoundationModels).
- Produces: final user-facing behavior; nothing downstream.

- [ ] **Step 1: Replace `DetectorsSettingsView.swift` entirely**

```swift
// Bokashi/Settings/DetectorsSettingsView.swift
import FoundationModels
import SwiftUI

struct DetectorsSettingsView: View {
    @State private var settings = DetectionSettings.shared
    @State private var dev = DeveloperSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("All detection runs entirely on this Mac. Nothing ever leaves your machine.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Use Apple Intelligence detection", isOn: $settings.aiDetectionEnabled)
                availabilityLabel
                Text("Finds sensitive text the pattern-based detectors miss: usernames and handles, API keys and other secrets, credit card numbers, and names in context.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Mask faces and avatars", isOn: $settings.faceMaskingEnabled)
                Text("Masks any detected face, including profile pictures. Individual masks can be removed with the eraser.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Developer").font(.caption).foregroundStyle(.secondary)
                Toggle("Highlight mask source in editor", isOn: $dev.highlightMaskSource)
                Text("Outlines auto-detected mosaics with a colored dashed border in the editor: blue = OCR / regex / NLTagger, orange = Apple Intelligence, green = faces.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var availabilityLabel: some View {
        switch SystemLanguageModel.default.availability {
        case .available:
            Label("Apple Intelligence is ready", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .unavailable(.appleIntelligenceNotEnabled):
            Label(
                "Turn on Apple Intelligence in System Settings to use this",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
        case .unavailable(.modelNotReady):
            Label(
                "The on-device model is still getting ready — try again later",
                systemImage: "arrow.down.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        case .unavailable(.deviceNotEligible):
            Label(
                "Apple Intelligence is not supported on this Mac",
                systemImage: "xmark.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        case .unavailable:
            Label("Apple Intelligence is unavailable", systemImage: "xmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

(The old file's `TestStatus`, `statusLabel`, `runConnectionTest`, and the whole `OllamaConnectionTester` enum disappear with this replacement.)

- [ ] **Step 2: Add the settings check to `prewarmIfNeeded`**

In `Bokashi/Detection/AppleIntelligenceSensitiveRegionDetector.swift`, change:

```swift
    static func prewarmIfNeeded() {
        guard isModelAvailable else { return }
        LanguageModelSession(instructions: instructions).prewarm()
    }
```

to:

```swift
    static func prewarmIfNeeded() {
        guard DetectionSettings.shared.aiDetectionEnabled, isModelAvailable else { return }
        LanguageModelSession(instructions: instructions).prewarm()
    }
```

- [ ] **Step 3: Prewarm on editor open**

In `Bokashi/Editor/EditorWindowController.swift`, the init's task currently reads:

```swift
        Task { @MainActor [state, image, autoMaskOnCapture] in
            await state.runOCR(on: image)
```

Insert the prewarm call as the task's first line:

```swift
        Task { @MainActor [state, image, autoMaskOnCapture] in
            AppleIntelligenceSensitiveRegionDetector.prewarmIfNeeded()
            await state.runOCR(on: image)
```

- [ ] **Step 4: Update the debug color legend**

In `Bokashi/Editor/AnnotationCanvas.swift`, replace:

```swift
    private static func debugColor(for source: String) -> Color {
        switch source {
        case "ocr": return .blue
        case "ollama": return .orange
        default: return .gray
        }
    }
```

with:

```swift
    private static func debugColor(for source: String) -> Color {
        switch source {
        case "ocr": return .blue
        case "appleIntelligence": return .orange
        case "face": return .green
        default: return .gray
        }
    }
```

- [ ] **Step 5: Clear obsolete defaults at launch**

In `Bokashi/AppDelegate.swift`, change:

```swift
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.setUp()
        migrateCaptureHotkeysIfNeeded()
        registerHotkeys()
    }
```

to:

```swift
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.setUp()
        DetectionSettings.removeObsoleteOllamaDefaults()
        migrateCaptureHotkeysIfNeeded()
        registerHotkeys()
    }
```

- [ ] **Step 6: Regenerate and build**

Run: `xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7: Commit**

```bash
git add Bokashi/Settings/DetectorsSettingsView.swift \
        Bokashi/Detection/AppleIntelligenceSensitiveRegionDetector.swift \
        Bokashi/Editor/EditorWindowController.swift \
        Bokashi/Editor/AnnotationCanvas.swift \
        Bokashi/AppDelegate.swift
git commit -m "feat: Apple Intelligence settings UI, prewarm, and debug colors"
```

---

### Task 9: Delete the Ollama detector

Everything is unreferenced after Tasks 7–8; delete it and refresh the one doc comment that named local vision LLMs as the plugin example.

**Files:**
- Delete: `Bokashi/Detection/OllamaSensitiveRegionDetector.swift`
- Delete: `Bokashi/Settings/OllamaDetectorSettings.swift`
- Modify: `Packages/BokashiCore/Sources/BokashiCore/Detection/SensitiveRegionDetector.swift:15-19` (doc comment)

**Interfaces:**
- Consumes: nothing. Produces: nothing.

- [ ] **Step 1: Delete the two files**

```bash
git rm Bokashi/Detection/OllamaSensitiveRegionDetector.swift \
       Bokashi/Settings/OllamaDetectorSettings.swift
```

- [ ] **Step 2: Update the protocol doc comment**

In `SensitiveRegionDetector.swift`, replace:

```swift
/// A pluggable detector that returns rectangles in image-pixel coordinates
/// that should be masked. Implementations may use OCR + heuristics (current
/// path), bundled CoreML models, local vision LLMs, or anything else; the
/// orchestrator merges their output and feeds it into the annotation
/// pipeline.
```

with:

```swift
/// A pluggable detector that returns rectangles in image-pixel coordinates
/// that should be masked. Implementations may use OCR + heuristics, Vision
/// requests, the on-device Foundation Models LLM, bundled CoreML models, or
/// anything else; the orchestrator merges their output and feeds it into
/// the annotation pipeline.
```

- [ ] **Step 3: Verify no stragglers**

Run: `grep -rni ollama Bokashi/ Packages/ project.yml README.md CLAUDE.md`
Expected: no output. (`CHANGELOG.md` still mentions Ollama in the v0.5.0 history, and `docs/superpowers/` discusses it by design — both stay.)

- [ ] **Step 4: Regenerate, build, run package tests**

Run: `xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO && swift test --package-path Packages/BokashiCore`
Expected: `BUILD SUCCEEDED`, all tests pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: remove the Ollama vision-LLM detector"
```

---

### Task 10: Roadmap update and end-to-end verification

**Files:**
- Modify: `docs/ROADMAP.md` (Detection backlog section, around lines 94-104)

**Interfaces:**
- Consumes: everything. Produces: the shippable branch.

- [ ] **Step 1: Update `docs/ROADMAP.md`**

In the `### Detection` backlog section, the current text reads:

```markdown
Privacy-first: every detector runs on-device; cloud LLM APIs are
explicitly excluded.

- Reviewable detection candidates (preview boxes before applying)
- Local CoreML detector for chat-app UI patterns (Slack / Twitter /
  Discord) — bundled or downloadable model packs
- More auto-detectors: credit cards, IP addresses, AWS keys, My Number
```

Replace it with:

```markdown
Privacy-first: every detector runs on-device; cloud LLM APIs are
explicitly excluded. The LLM layer is Apple's on-device Foundation
Models (macOS 26+; replaced the Ollama vision-LLM detector in 2026-07)
with a Vision face detector covering avatars.

- Reviewable detection candidates (preview boxes before applying)
- Local CoreML detector for chat-app UI patterns (Slack / Twitter /
  Discord) — bundled or downloadable model packs
- More auto-detectors: IP addresses, AWS keys, My Number (credit
  cards and API keys are now covered by the Apple Intelligence
  detector on eligible machines)
- Multimodal Foundation Models input for avatar-precision masking —
  revisit when the OS-27 device matrix is clear
```

- [ ] **Step 2: Full automated verification**

Run: `swift test --package-path Packages/BokashiCore && xcodegen && xcodebuild -project Bokashi.xcodeproj -scheme Bokashi -configuration Debug build CODE_SIGNING_ALLOWED=NO`
Expected: all package tests pass; `BUILD SUCCEEDED`.

- [ ] **Step 3: Manual end-to-end check (maintainer's Mac, signed dev build)**

Build and launch via Xcode (normal signed build so TCC screen-recording permission holds), then:

1. Settings → Detectors shows the new UI; the status row reads "Apple Intelligence is ready".
2. Capture a window showing sample content with a handle (`@somebody`), an email, a phone number, an API-key-like string, and a face/avatar (e.g. a GitHub profile page).
3. Click **Detect**: masks appear over the sensitive strings and the face. With Settings → Developer → "Highlight mask source" ON: blue = OCR-based, orange = Apple Intelligence, green = face; no doubled mask on the email (dedup working).
4. Toggle "Use Apple Intelligence detection" OFF → Detect again: orange-source masks gone, blue and green remain. Same for "Mask faces and avatars" → green gone.
5. System Settings → Apple Intelligence OFF → relaunch app → Settings shows the orange "Turn on Apple Intelligence…" hint; Detect still produces OCR-based masks with no error UI. Turn Apple Intelligence back ON afterwards.
6. `defaults read com.snaka.Bokashi | grep -i ollama` → no output (obsolete keys cleared at launch).

Record any deviation as a bug before proceeding.

- [ ] **Step 4: Commit**

```bash
git add docs/ROADMAP.md
git commit -m "docs: record Foundation Models detector in roadmap"
```

---

## Release note (outside this plan)

Per `RELEASE.md` house flow, `CHANGELOG.md` is written by the v0.9.0 release-prep PR, not on this branch. That section must include: Added — Apple Intelligence detector + face/avatar masking; Removed — Ollama detector (and its settings); Changed — **breaking:** Bokashi now requires macOS 26.
