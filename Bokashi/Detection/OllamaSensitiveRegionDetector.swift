import BokashiCore
import CoreGraphics
import Foundation

@MainActor
struct OllamaSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "ollama"

    let endpoint: String
    let model: String
    let urlSession: URLSession

    init(endpoint: String, model: String, urlSession: URLSession = .shared) {
        self.endpoint = endpoint
        self.model = model
        self.urlSession = urlSession
    }

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty, !trimmedEndpoint.isEmpty else { return [] }

        let chatURL: URL
        if let resolved = URL(string: trimmedEndpoint)?.appendingPathComponent("api/chat") {
            chatURL = resolved
        } else {
            return []
        }

        let imageData: Data
        do {
            imageData = try PNGWriter.data(from: image)
        } catch {
            return []
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "model": trimmedModel,
            "stream": false,
            "format": "json",
            "messages": [
                [
                    "role": "user",
                    "content": Self.prompt,
                    "images": [base64],
                ]
            ],
        ]
        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return []
        }

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = bodyData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            return []
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }

        guard
            let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = envelope["message"] as? [String: Any],
            let content = message["content"] as? String,
            let contentData = content.data(using: .utf8)
        else {
            return []
        }

        guard
            let decoded = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
            let raws = decoded["regions"] as? [[String: Any]]
        else {
            return []
        }

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)

        return raws.compactMap { raw -> DetectedRegion? in
            guard
                let nx = numericValue(raw["x"]),
                let ny = numericValue(raw["y"]),
                let nw = numericValue(raw["width"]),
                let nh = numericValue(raw["height"])
            else {
                return nil
            }
            let label = (raw["label"] as? String) ?? "ollama"

            let pxRect = CGRect(
                x: nx * imageWidth,
                y: ny * imageHeight,
                width: nw * imageWidth,
                height: nh * imageHeight
            ).integral

            guard pxRect.width >= 4, pxRect.height >= 4 else { return nil }

            let clamped = pxRect.intersection(
                CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
            )
            guard !clamped.isNull, clamped.width >= 4, clamped.height >= 4 else { return nil }

            return DetectedRegion(rect: clamped, label: label)
        }
    }

    // MARK: - Helpers

    private static let prompt: String = """
        Identify regions in this screenshot that contain personally identifiable info: \
        personal names, usernames, account handles, profile avatars (small circular \
        profile pictures), email addresses, phone numbers.
        Return ONLY JSON of the form:
        {"regions":[{"label":"name","x":0.10,"y":0.05,"width":0.20,"height":0.04}]}
        Coordinates are normalized in [0,1] with (0,0) at the top-left and (1,1) at \
        the bottom-right. Each region must be a tight bounding box around the sensitive \
        item. Do not include UI chrome or generic text. Return an empty regions array \
        if nothing sensitive is visible.
        """

    private func numericValue(_ raw: Any?) -> CGFloat? {
        if let n = raw as? NSNumber { return CGFloat(truncating: n) }
        if let s = raw as? String, let d = Double(s) { return CGFloat(d) }
        return nil
    }
}
