import Foundation
import Logging
import AppKit

public class InputBuffer {
    private let logger = Logger(label: "com.novakey.inputbuffer")
    private var buffer: String = ""
    private let maxBufferSize: Int
    private let flushInterval: TimeInterval
    private var flushTimer: Timer?
    private let ollamaClient: OllamaClient
    
    public init(maxBufferSize: Int = 100, flushInterval: TimeInterval = 5.0, ollamaClient: OllamaClient = OllamaClient()) {
        self.maxBufferSize = maxBufferSize
        self.flushInterval = flushInterval
        self.ollamaClient = ollamaClient
        startFlushTimer()
    }
    
    public func append(_ text: String) {
        buffer += text
        if buffer.count >= maxBufferSize {
            flush()
        }
    }
    
    public func flush() {
        guard !buffer.isEmpty else { return }
        let currentBuffer = buffer
        buffer = ""
        logger.info("バッファをフラッシュしました: \(currentBuffer)")
        
        Task {
            do {
                let convertedText = try await ollamaClient.convertToJapanese(currentBuffer)
                logger.info("変換結果: \(convertedText)")
                
                // クリップボードに変換結果をコピー
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(convertedText, forType: .string)
            } catch {
                logger.error("変換に失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }
    
    deinit {
        flushTimer?.invalidate()
    }
} 