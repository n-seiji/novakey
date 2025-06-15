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

    public func convertToKanji(_ input: String) async throws -> String {
        let prompt = """
        # 役割
        あなたは日本語変換エンジンとして振る舞います。
        
        # タスク
        入力に対してJSONで「\"output\": \"...\"」の形でひらがなを漢字に変換した結果を返してください。

        # 注意
        - ローマ字入力はそのままにすること
        
        # 入力
        \(input)
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        return try await sendLLM(requestBody)
    }
    

    private func sendLLM(_ requestBody: [String: Any]) async throws -> String {
        
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
    }
}

private struct OllamaResponse: Codable {
    let response: String
} 