# BlackBox
iOS wrapper library for Unified Logging, and more.

## Installation

1. Add BlackBox as a dependency
```ruby
pod 'BlackBox', :source => 'git@github.com:dodopizza/dodo_pods.git'
```
2. Import to your project
```swift
import BlackBox
```
3. Configure instance with desired loggers
```swift
BlackBox.instance = BlackBox(loggers: [BlackBox.OSLogger()])
```

## Available loggers
1. `OSLogger` — logs to macOS Console.app
2. `FSLogger` — logs to file. Slow, use at your own risk.
3. `OSSignpostLogger` — logs to Time Profiler

## Usage
1. Simple message
```swift
BlackBox.log("Hello world")
```
2. Message with additional info
```swift
BlackBox.log("Logged in", userInfo: ["userId": someUserId]) // keep in mind to not include sensitive info in logs
```
3. Message with category
```swift
BlackBox.log("Logged in", userInfo: ["userId": someUserId], category: "App lifecycle") // keep in mind to not include sensitive info in logs
```
4. Message with custom log level
```swift
BlackBox.log("Tried to open AuthScreen multiple times", logLevel: .warning)
```
5. Error
```swift
enum ParsingError: Error {
    case unknownCategoryInDTO(rawValue: Int)
}

BlackBox.log(ParsingError.unknownCategoryInDTO(rawValue: 9))
```
6. Time Profiler, `OSSignpostLogger` is required
```swift
BlackBox.log("Will parse menu", eventType: .begin)
let menuModel = MenuModel(dto: menuDto)
BlackBox.log("Did parse menu", eventType: .end)
```
7. Time Profiler with concurrent async operations
```swift
let eventId = UInt64.random // basically any unique UInt64 is required

BlackBox.log("Will load data for network request", eventType: .begin, eventId: eventId)
request.get() { response in
    BlackBox.log("Did load data for request", eventType: .end, eventId: eventId)
}
```

## Adding custom loggers
Create your own logger and implement `BBLoggerProtocol`

### Example
```swift
extension BlackBox {
    class CrashlyticsLogger: BBLoggerProtocol {
        func log(_ error: Error,
                 file: StaticString,
                 category: String?,
                 function: StaticString,
                 line: UInt) {
            if true {
                Crashlytics.crashlytics().record(error: error)
            }
            
            log(String(reflecting: error),
                userInfo: nil,
                logLevel: .error,
                eventType: nil,
                eventId: nil,
                file: file,
                category: category,
                function: function,
                line: line)
        }
        
        func log(_ message: String,
                 userInfo: CustomDebugStringConvertible?,
                 logLevel: BBLogLevel,
                 eventType: BBEventType?,
                 eventId: UInt64?,
                 file: StaticString,
                 category: String?,
                 function: StaticString,
                 line: UInt) {
            let message = self.message(from: message,
                                       with: logLevel)
            Crashlytics.crashlytics().log(message)
        }
    }
}

extension BlackBox.CrashlyticsLogger {
    private func message(from message: String, with logLevel: BBLogLevel) -> String {
        switch logLevel {
        case .debug, .info, .default:
            return message
        case .error, .warning:
            return logLevel.icon + " " + message
        }
    }
}
```
And dont forget to include your custom logger to BlackBox
```swift
BlackBox.instance = BlackBox(loggers: [BlackBox.OSLogger(), BlackBox.CrashlyticsLogger()])
```

For better Crashlytics support implement `CustomNSError` and override both `errorCode` and `errorUserInfo` 
```swift
extension ParsingError: CustomNSError {
    var errorCode: Int {
        switch self {
        case .unknownCategoryInDTO:
            return 0
	}
    }

    var errorUserInfo: [String : Any] {
        switch self {
        case .unknownCategoryInDTO(let rawValue):
            return ["rawValue": rawValue]
        }
    }
}
```
