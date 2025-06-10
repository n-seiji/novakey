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
    
    public func sendLLM(_ input: String) async throws -> String {
        let url = baseURL.appendingPathComponent("api/generate")
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return response.response
    }
}

private struct OllamaResponse: Codable {
    let response: String
} 