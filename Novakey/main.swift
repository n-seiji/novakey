import Cocoa
import InputMethodKit
import Logging

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var server: IMKServer!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        LoggingSystem.bootstrap { label in
            StreamLogHandler.standardOutput(label: label)
        }
        
        let logger = Logger(label: "com.novakey.inputmethod")
        logger.info("Novakey Input Method starting...")
        
        let identifier = Bundle.main.bundleIdentifier!
        server = IMKServer(name: "Novakey_1_Connection", bundleIdentifier: identifier)
        
        logger.info("Input Method Server initialized with identifier: \(identifier)")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        let logger = Logger(label: "com.novakey.inputmethod")
        logger.info("Novakey Input Method terminating...")
    }
}