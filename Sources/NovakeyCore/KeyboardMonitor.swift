import Foundation
import CoreGraphics
import Logging
import ApplicationServices
import AppKit

public class KeyboardMonitor {
    private let logger = Logger(label: "com.novakey.keyboardmonitor")
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isMonitoring = false
    
    private let inputBuffer: InputBuffer
    private let ollamaClient: OllamaClient
    
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
        "wa": "わ", "wo": "を", "n": "ん",
        
        // 小文字
        "xa": "ぁ", "xi": "ぃ", "xu": "ぅ", "xe": "ぇ", "xo": "ぉ",
        "xya": "ゃ", "xyu": "ゅ", "xyo": "ょ",
        "xtu": "っ", "xtsu": "っ",
        
        // 特殊な組み合わせ
        "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
        "gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
        "sha": "しゃ", "shu": "しゅ", "sho": "しょ",
        "ja": "じゃ", "ju": "じゅ", "jo": "じょ",
        "cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ",
        "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
        "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
        "bya": "びゃ", "byu": "びゅ", "byo": "びょ",
        "pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
        "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
        "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ"
    ]
    
    // キーコードから文字への変換マップ
    private let keyCodeToChar: [Int64: String] = [
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g",
        6: "z", 7: "x", 8: "c", 9: "v", 11: "b", 12: "q",
        13: "w", 14: "e", 15: "r", 16: "y", 17: "t",
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-",
        28: "8", 29: "0", 30: "]", 31: "o", 32: "u",
        33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
        39: "'", 40: "k", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "n", 46: "m", 47: ".", 50: "`"
    ]
    
    private var currentInput: String = ""
    private var lastInputTime: Date = Date()
    private let conversionDelay: TimeInterval = 2.0
    private var conversionTimer: Timer?
    
    public init(inputBuffer: InputBuffer = InputBuffer(), ollamaClient: OllamaClient = OllamaClient()) {
        self.inputBuffer = inputBuffer
        self.ollamaClient = ollamaClient
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        // アクセシビリティ権限の確認
        if !AXIsProcessTrusted() {
            logger.error("アクセシビリティ権限が必要です")
            print("アクセシビリティ権限が必要です。システム環境設定 > プライバシーとセキュリティ > アクセシビリティで権限を付与してください。")
            return
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            logger.error("イベントタップの作成に失敗しました")
            print("イベントタップの作成に失敗しました。アクセシビリティ権限を確認してください。")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource = runLoopSource else {
            logger.error("RunLoopSourceの作成に失敗しました")
            return
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isMonitoring = true
        logger.info("キーボード監視を開始しました")
        print("キーボード監視を開始しました。")
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        logger.info("キーボード監視を停止しました")
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        let isShift = flags.contains(.maskShift)
        let isControl = flags.contains(.maskControl)
        let isOption = flags.contains(.maskAlternate)
        let isCommand = flags.contains(.maskCommand)
        
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            let appName = activeApp.localizedName ?? "Unknown"
            
            if type == .keyDown {
                if let char = convertKeyCodeToChar(keyCode, flags: flags) {
                    currentInput += char
                    lastInputTime = Date()
                    
                    // 変換トリガー文字のチェック
                    if char == "." || char == "," {
                        convertAndFlushInput()
                    } else {
                        // 変換タイマーのリセット
                        conversionTimer?.invalidate()
                        conversionTimer = Timer.scheduledTimer(withTimeInterval: conversionDelay, repeats: false) { [weak self] _ in
                            self?.convertAndFlushInput()
                        }
                    }
                }
            }
            
            logger.info("""
                [\(appName)] Key: \(keyCode) \
                (Shift: \(isShift), Control: \(isControl), \
                Option: \(isOption), Command: \(isCommand))
                """)
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func convertKeyCodeToChar(_ keyCode: Int64, flags: CGEventFlags) -> String? {
        // 修飾キーが押されている場合は変換しない
        if flags.contains(.maskShift) || flags.contains(.maskControl) || 
           flags.contains(.maskAlternate) || flags.contains(.maskCommand) {
            return nil
        }
        
        return keyCodeToChar[keyCode]
    }
    
    private func convertRomajiToHiragana(_ input: String) -> String? {
        // 入力が空の場合は変換しない
        if input.isEmpty {
            return nil
        }
        
        logger.info("input: \(input)")
        
        // 入力文字列を先頭から順に変換
        var result = ""
        var remaining = input.lowercased()
        
        while !remaining.isEmpty {
            var found = false
            var maxLength = 0
            var matchedHiragana: String? = nil
            
            // 最長のマッチを探す（3文字、2文字、1文字の順で確認）
            for length in (1...3).reversed() {
                if remaining.count >= length {
                    let prefix = String(remaining.prefix(length))
                    if let hiragana = romajiToHiragana[prefix] {
                        maxLength = length
                        matchedHiragana = hiragana
                        found = true
                        break
                    }
                }
            }
            
            if found, let hiragana = matchedHiragana {
                result += hiragana
                remaining = String(remaining.dropFirst(maxLength))
            } else {
                // マッチするものが見つからない場合は、最初の1文字をそのまま追加
                result += String(remaining.prefix(1))
                remaining = String(remaining.dropFirst(1))
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    private func convertAndFlushInput() {
        guard !currentInput.isEmpty else { return }
        
        if let hiragana = convertRomajiToHiragana(currentInput) {
            inputBuffer.append(hiragana)
        }
        currentInput = ""
    }
} 
