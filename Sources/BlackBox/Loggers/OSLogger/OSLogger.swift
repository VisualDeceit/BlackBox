import Foundation
import os

@available(iOS 12.0, *)
extension BlackBox {
    public class OSLogger: BBLoggerProtocol {
        let logLevels: [BBLogLevel]
        
        public init(logLevels: [BBLogLevel]){
            self.logLevels = logLevels
        }
        
        public func log(_ error: Error,
                        eventType: BBEventType,
                        eventId: UInt64?,
                        file: StaticString,
                        category: String?,
                        function: StaticString,
                        line: UInt) {
            guard logLevels.contains(.error) else { return }
            
            let message = String(reflecting: error)
            
            log(message,
                userInfo: nil,
                logLevel: error.logLevel,
                eventType: eventType,
                eventId: eventId,
                file: file,
                category: category,
                function: function,
                line: line)
        }
        
        public func log(_ message: String,
                        userInfo: CustomDebugStringConvertible?,
                        logLevel: BBLogLevel,
                        eventType: BBEventType,
                        eventId: UInt64?,
                        file: StaticString,
                        category: String?,
                        function: StaticString,
                        line: UInt) {
            guard logLevels.contains(logLevel) else { return }
            
            log(message,
                userInfo: userInfo,
                logger: OSLog(file: file, category: category),
                file: file,
                function: function,
                logType: OSLogType(logLevel))
        }
    }
}

@available(iOS 12.0, *)
extension BlackBox.OSLogger {
    private func log(_ message: String,
                     userInfo: CustomDebugStringConvertible?,
                     logger: OSLog,
                     file: StaticString,
                     function: StaticString,
                     logType: OSLogType) {
        let userInfo = userInfo?.bbLogDescription ?? "nil"
        let message = message + "\n\n" + "[User Info]:" + "\n" + userInfo
        
        os_log(logType,
               log: logger,
               "%{public}@\n%{public}@", function.description, message)
    }
}

@available(iOS 12.0, *)
extension OSLog {
    convenience init(file: StaticString, category: String?) {
        self.init(subsystem: file.bbFilename, category: category ?? "")
    }
}

@available(iOS 12.0, *)
extension OSLogType {
    init(_ logLevel: BBLogLevel) {
        switch logLevel {
        case .debug:
            self = .default // .debug won't be shown in Console.app, so switching to .default instead
        case .default:
            self = .default
        case .info:
            self = .info
        case .warning:
            self = .error
        case .error:
            self = .fault
        }
    }
}