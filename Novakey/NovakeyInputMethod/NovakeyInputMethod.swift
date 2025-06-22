import InputMethodKit
import NovakeyCore
import Logging

@objc(NovakeyInputMethodController)
class NovakeyInputMethodController: IMKInputController {
    private let ollamaClient: OllamaClient
    private let logger = Logger(label: "NovakeyInputMethod")
    private var currentInput: String = ""
    
    // ローマ字からひらがなへの変換マップ
    private let romajiToHiragana: [String: String] = [
        // 基本的な母音
        "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
        
        // か行
        "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
        "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
        
        // さ行
        "sa": "さ", "si": "し", "shi": "し", "su": "す", "se": "せ", "so": "そ",
        "za": "ざ", "zi": "じ", "ji": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
        
        // た行
        "ta": "た", "ti": "ち", "chi": "ち", "tu": "つ", "tsu": "つ", "te": "て", "to": "と",
        "da": "だ", "di": "ぢ", "du": "づ", "de": "で", "do": "ど",
        
        // な行
        "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
        
        // は行
        "ha": "は", "hi": "ひ", "fu": "ふ", "he": "へ", "ho": "ほ",
        "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
        "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
        
        // ま行
        "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
        
        // や行
        "ya": "や", "yu": "ゆ", "yo": "よ",
        
        // ら行
        "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
        
        // わ行
        "wa": "わ", "wo": "を", "n": "ん"
    ]
    
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        self.ollamaClient = OllamaClient()
        super.init(server: server, delegate: delegate, client: inputClient)
        logger.info("NovakeyInputMethodController initialized")
    }
    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard event.type == .keyDown else { return false }
        
        let inputText = event.characters ?? ""
        logger.debug("Received input: \(inputText)")
        
        // スペースキーで変換実行
        if inputText == " " {
            convertAndCommit()
            return true
        }
        
        // アルファベットの場合は蓄積
        if inputText.allSatisfy({ $0.isLetter && $0.isASCII }) {
            currentInput += inputText.lowercased()
            updateComposition()
            return true
        }
        
        return false
    }
    
    override func updateComposition() {
        let hiragana = convertRomajiToHiragana(currentInput)
        client()?.setMarkedText(hiragana, selectionRange: NSRange(location: hiragana.count, length: 0), replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    }
    
    private func convertRomajiToHiragana(_ input: String) -> String {
        var result = ""
        var remaining = input.lowercased()
        
        while !remaining.isEmpty {
            var found = false
            
            // 最長のマッチを探す（3文字、2文字、1文字の順で確認）
            for length in (1...3).reversed() {
                if remaining.count >= length {
                    let prefix = String(remaining.prefix(length))
                    if let hiragana = romajiToHiragana[prefix] {
                        result += hiragana
                        remaining = String(remaining.dropFirst(length))
                        found = true
                        break
                    }
                }
            }
            
            if !found {
                result += String(remaining.prefix(1))
                remaining = String(remaining.dropFirst(1))
            }
        }
        
        return result
    }
    
    private func convertAndCommit() {
        guard !currentInput.isEmpty else { return }
        
        let hiragana = convertRomajiToHiragana(currentInput)
        
        Task { @MainActor in
            do {
                let kanji = try await ollamaClient.convertToKanji(hiragana)
                self.commitText(kanji)
                self.currentInput = ""
            } catch {
                logger.error("変換に失敗しました: \(error.localizedDescription)")
                self.commitText(hiragana)
                self.currentInput = ""
            }
        }
    }
    
    private func commitText(_ text: String) {
        client()?.insertText(text, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    }
    
    override func commitComposition(_ sender: Any!) {
        if !currentInput.isEmpty {
            let hiragana = convertRomajiToHiragana(currentInput)
            commitText(hiragana)
            currentInput = ""
        }
        super.commitComposition(sender)
    }
}