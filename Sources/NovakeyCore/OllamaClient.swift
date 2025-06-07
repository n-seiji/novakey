import Foundation
import Logging

public class OllamaClient {
    private let logger = Logger(label: "com.novakey.ollamaclient")
    private let baseURL: URL
    private let model: String
    
    public init(baseURL: URL = URL(string: "http://localhost:11434")!, model: String = "gemma3:1b") {
        self.baseURL = baseURL
        self.model = model
    }
    
    public func convertToJapanese(_ input: String) async throws -> String {
        // 開発中はダミー実装を使用
        // #if DEBUG
        // return "ダミー変換結果: \(input)"
        // #else
        let prompt = """
        以下の文字列を日本語に変換してください。漢字、ひらがな、カタカナを適切に使用してください：
        \(input)
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        
        var request = URLRequest(url: baseURL.appendingPathComponent("api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "OllamaClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIリクエストに失敗しました"])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(OllamaResponse.self, from: data)
        return result.response
        // #endif
    }
}

private struct OllamaResponse: Codable {
    let response: String
} 