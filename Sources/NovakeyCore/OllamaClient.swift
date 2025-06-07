import Foundation
import Logging

public class OllamaClient {
    private let logger = Logger(label: "com.novakey.ollamaclient")
    private let baseURL: URL
    private let model: String
    private let textProcessor: TextProcessor
    
    public init(baseURL: URL = URL(string: "http://localhost:11434")!, model: String = "gemma3:1b") {
        self.baseURL = baseURL
        self.model = model
        self.textProcessor = TextProcessor()
    }
    
    public func convertToJapanese(_ input: String) async throws -> String {
        // 開発中はダミー実装を使用
        // #if DEBUG
        // return "ダミー変換結果: \(input)"
        // #else
        
        // テキストを処理
        let processedText = textProcessor.processText(input)
        logger.debug("処理後のテキスト: \(processedText)")
        
        // プロンプトを生成
        let prompt = textProcessor.generatePrompt(processedText)
        logger.debug("生成されたプロンプト: \(prompt)")
        
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
        logger.debug("LLMからの応答: \(result.response)")
        return result.response
        // #endif
    }
}

private struct OllamaResponse: Codable {
    let response: String
} 