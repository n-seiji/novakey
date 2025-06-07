import Foundation
import Logging

public class TextProcessor {
    private let logger = Logger(label: "com.novakey.textprocessor")
    
    // 日本語文字の正規表現パターン
    private let japanesePattern = #"[ぁ-んァ-ン一-龯々〆ヵヶ]"#
    
    public init() {}
    
    /// テキストが日本語かどうかを判定
    public func isJapanese(_ text: String) -> Bool {
        let range = text.range(of: japanesePattern, options: .regularExpression)
        return range != nil
    }
    
    /// テキストを適切な形式に変換
    public func processText(_ text: String) -> String {
        if isJapanese(text) {
            logger.debug("日本語テキストを検出: \(text)")
            // TODO: 漢字・カタカナをひらがなに変換する処理を追加
            return text
        } else {
            logger.debug("英語テキストを検出: \(text)")
            return text
        }
    }
    
    /// プロンプトを生成
    public func generatePrompt(_ text: String) -> String {
        if isJapanese(text) {
            return """
            Convert the following Japanese text into natural Japanese. Your response must only be the converted text, without any additional words or explanations.
            
            [Input string here]
            \(text)
            """
        } else {
            return """
            Convert the following string into Japanese. Your response must only be the converted text, without any additional words or explanations.
            
            [Input string here]
            \(text)
            """
        }
    }
} 