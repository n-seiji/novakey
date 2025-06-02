import Foundation
import ArgumentParser
import Logging
import NovakeyCore

struct Novakey: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "novakey",
        abstract: "macOSのキーボード入力監視・ロギングサービス"
    )
    
    @Option(name: .long, help: "ログファイルのパス")
    var logFile: String?
    
    @Flag(name: .long, help: "デバッグモードで実行")
    var debug = false
    
    func run() throws {
        if let logFile = logFile {
            // ログファイルに追記モードで書き込む
            if !FileManager.default.fileExists(atPath: logFile) {
                FileManager.default.createFile(atPath: logFile, contents: nil, attributes: nil)
            }
            guard let fileHandle = FileHandle(forWritingAtPath: logFile) else {
                print("ログファイルを開けませんでした: \(logFile)")
                return
            }
            fileHandle.seekToEndOfFile()
            LoggingSystem.bootstrap { label in
                FileLogHandler(label: label, fileHandle: fileHandle)
            }
        } else {
            // 標準出力
            LoggingSystem.bootstrap { label in
                StreamLogHandler.standardOutput(label: label)
            }
        }
        
        let monitor = KeyboardMonitor()
        monitor.startMonitoring()
        
        // メインループを実行
        RunLoop.main.run()
    }
}

/// FileHandle用のLogHandler
struct FileLogHandler: LogHandler {
    let label: String
    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .info
    let fileHandle: FileHandle
    
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let log = "\(Date()) [\(level)] \(label): \(message)\n"
        if let data = log.data(using: .utf8) {
            fileHandle.write(data)
        }
    }
}

Novakey.main() 