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
    
    public init(inputBuffer: InputBuffer = InputBuffer(), ollamaClient: OllamaClient = OllamaClient()) {
        self.inputBuffer = inputBuffer
        self.ollamaClient = ollamaClient
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        // アクセシビリティ権限の確認
        if !AXIsProcessTrusted() {
            logger.error("アクセシビリティ権限が必要です")
            return
        }
        
        // イベントタップの作成
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
            return
        }
        
        // イベントタップを実行ループに追加
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // イベントタップを有効化
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isMonitoring = true
        logger.info("キーボード監視を開始しました")
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
        
        // 修飾キーの状態を取得
        let isShift = flags.contains(.maskShift)
        let isControl = flags.contains(.maskControl)
        let isOption = flags.contains(.maskAlternate)
        let isCommand = flags.contains(.maskCommand)
        
        // アクティブなアプリケーションの情報を取得
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            let appName = activeApp.localizedName ?? "Unknown"
            
            // キー入力を文字列に変換
            if type == .keyDown {
                if let keyString = convertKeyCodeToString(keyCode, flags: flags) {
                    inputBuffer.append(keyString)
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
    
    private func convertKeyCodeToString(_ keyCode: Int64, flags: CGEventFlags) -> String? {
        // 基本的なキーコードから文字への変換
        let keyMap: [Int64: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g",
            6: "z", 7: "x", 8: "c", 9: "v", 11: "b", 12: "q",
            13: "w", 14: "e", 15: "r", 16: "y", 17: "t",
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-",
            28: "8", 29: "0", 30: "]", 31: "o", 32: "u",
            33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
            39: "'", 40: "k", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "n", 46: "m", 47: ".", 50: "`",
            65: ".", 67: "*", 69: "+", 71: "CLEAR",
            75: "/", 76: "ENTER", 78: "-", 81: "=",
            82: "0", 83: "1", 84: "2", 85: "3", 86: "4",
            87: "5", 88: "6", 89: "7", 91: "8", 92: "9"
        ]
        
        if let baseChar = keyMap[keyCode] {
            if flags.contains(.maskShift) {
                return baseChar.uppercased()
            }
            return baseChar
        }
        
        return nil
    }
} 
