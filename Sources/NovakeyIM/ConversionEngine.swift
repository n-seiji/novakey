import Foundation

class ConversionEngine {
    static let shared = ConversionEngine()
    
    private init() {}
    
    func getCandidates(for input: String) -> [String] {
        // TODO: 実際の変換ロジックを実装
        // 現在はダミーの実装
        return [input, "変換候補1", "変換候補2"]
    }
    
    func learn(from input: String, to output: String) {
        // TODO: 学習機能の実装
    }
} 