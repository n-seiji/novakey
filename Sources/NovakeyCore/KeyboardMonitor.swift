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
    
    public init() {}
    
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
            logger.info("""
                [\(appName)] Key: \(keyCode) \
                (Shift: \(isShift), Control: \(isControl), \
                Option: \(isOption), Command: \(isCommand))
                """)
        }
        
        return Unmanaged.passRetained(event)
    }
} 
