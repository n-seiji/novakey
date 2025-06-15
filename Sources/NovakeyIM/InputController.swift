import InputMethodKit
import NovakeyCore

class InputController: IMKInputController {
    private var currentInput: String = ""
    private var candidates: [String] = []
    private var candidatesWindow: IMKCandidates?
    
    override init!(server: IMKServer!, delegate: Any!, client: Any!) {
        super.init(server: server, delegate: delegate, client: client)
        candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleColumnScrollingCandidatePanel)
    }
    
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else { return false }
        
        // スペースキーで変換開始
        if string == " " {
            if !currentInput.isEmpty {
                candidates = ConversionEngine.shared.getCandidates(for: currentInput)
                showCandidates()
            }
            return true
        }
        
        // エンターキーで確定
        if string == "\r" {
            if !currentInput.isEmpty {
                client.insertText(currentInput, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
                currentInput = ""
                hideCandidates()
            }
            return true
        }
        
        // 通常の文字入力
        currentInput += string
        client.insertText(string, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        
        return true
    }
    
    private func showCandidates() {
        candidatesWindow?.update()
        candidatesWindow?.show()
    }
    
    private func hideCandidates() {
        candidatesWindow?.hide()
    }
    
    override func candidates(_ sender: Any!) -> [Any]! {
        return candidates
    }
    
    override func candidateSelected(_ candidateString: NSAttributedString!) {
        guard let client = self.client() as? IMKTextInput else { return }
        
        // 選択された候補を挿入
        client.insertText(candidateString.string, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        
        // 状態をリセット
        currentInput = ""
        hideCandidates()
    }
} 