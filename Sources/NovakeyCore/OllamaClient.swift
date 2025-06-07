import Foundation
import Logging

public class OllamaClient {
    private let logger = Logger(label: "com.novakey.ollamaclient")
    private let baseURL: URL
    private let model: String
    
    // ローマ字からひらがなへの変換マップ
    private let romajiToHiragana: [String: String] = [
        // 基本的な母音
        "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
        // か行
        "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
        "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
        // さ行
        "sa": "さ", "si": "し", "shi": "し", "su": "す", "se": "せ", "so": "そ",
        "sha": "しゃ", "shu": "しゅ", "sho": "しょ",
        "sya": "しゃ", "syu": "しゅ", "syo": "しょ",
        // た行
        "ta": "た", "ti": "ち", "chi": "ち", "tu": "つ", "tsu": "つ", "te": "て", "to": "と",
        "cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ",
        "tya": "ちゃ", "tyu": "ちゅ", "tyo": "ちょ",
        // な行
        "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
        "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
        // は行
        "ha": "は", "hi": "ひ", "fu": "ふ", "hu": "ふ", "he": "へ", "ho": "ほ",
        "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
        // ま行
        "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
        "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
        // や行
        "ya": "や", "yu": "ゆ", "yo": "よ",
        // ら行
        "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
        "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
        // わ行
        "wa": "わ", "wo": "を", "n": "ん",
        // 濁音
        "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
        "gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
        "za": "ざ", "zi": "じ", "ji": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
        "ja": "じゃ", "ju": "じゅ", "jo": "じょ",
        "zya": "じゃ", "zyu": "じゅ", "zyo": "じょ",
        "da": "だ", "di": "ぢ", "du": "づ", "de": "で", "do": "ど",
        "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
        "bya": "びゃ", "byu": "びゅ", "byo": "びょ",
        "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
        "pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
        // 小さい文字
        "xtsu": "っ", "xtu": "っ",
        "xa": "ぁ", "xi": "ぃ", "xu": "ぅ", "xe": "ぇ", "xo": "ぉ",
        "xya": "ゃ", "xyu": "ゅ", "xyo": "ょ",
        // 記号
        ",": "、", ".": "。", "-": "ー", "!": "！", "?": "？"
    ]
    
    public init(baseURL: URL = URL(string: "http://localhost:11434")!, model: String = "gemma3:1b") {
        self.baseURL = baseURL
        self.model = model
    }
    
    public func convertToJapanese(_ input: String) async throws -> String {
        let input = input.lowercased()
        var result = ""
        var buffer = ""
        
        for char in input {
            buffer += String(char)
            
            // バッファが変換マップに存在するか確認
            if let hiragana = romajiToHiragana[buffer] {
                result += hiragana
                buffer = ""
            } else if buffer.count >= 4 {
                // 4文字以上でマッチしない場合は、最初の文字をそのまま出力
                result += String(buffer.first!)
                buffer = String(buffer.dropFirst())
            }
        }
        
        // 残りのバッファを処理
        if !buffer.isEmpty {
            if let hiragana = romajiToHiragana[buffer] {
                result += hiragana
            } else {
                result += buffer
            }
        }
        
        return result
    }
}

private struct OllamaResponse: Codable {
    let response: String
} 