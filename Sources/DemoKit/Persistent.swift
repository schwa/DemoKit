import Foundation
import SwiftUI
@_implementationOnly import os

private let logger: Logger? = nil // = Logger(subsystem: "TODO", category: "MiniDatabase")

@propertyWrapper
struct Persistent <Value> where Value: Codable {
    var wrappedValue: Value {
        mutating get {
            return try! read()
        }
        set {
            try! write(value: newValue)
        }
    }

    let url: URL
    var cachedValue: Value?

    init(wrappedValue: Value, url: URL) {
        logger?.debug("URL: \(url.path)")
        self.url = url
        if FileManager().fileExists(at: url) {
            try! read()
        }
        else {
            try! write(value: wrappedValue)
        }
    }
    
    @discardableResult
    mutating func read() throws -> Value {
        if let cachedValue {
            logger?.debug("Read. Cache hit.")
            return cachedValue
        }
        logger?.debug("Read. Cache miss.")
        let data = try Data(contentsOf: url)
        let value = try JSONDecoder().decode(Value.self, from: data)
        self.cachedValue = value
        return value
    }
    
    mutating func write(value: Value) throws {
        logger?.debug("Write")
        self.cachedValue = value
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: url)
    }
    
}

extension Persistent: DynamicProperty {
    mutating func update() {
        try! read()
    }
}
