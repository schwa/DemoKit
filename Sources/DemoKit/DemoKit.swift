internal import os
import SwiftUI

public struct DemoMetadata: Identifiable, Sendable {
    public var id: ID
    public var name: String
    public var systemImage: String
    public var description: String?
    public var group: String?
    public var keywords: [String]
    public var color: Color?
    public var isEnabled: Bool
    public var variants: [Self] = []

    public struct ID: Hashable, Sendable {
        public var rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public init(id: ID? = nil, name: String? = nil, systemImage: String = "puzzlepiece", description: String? = nil, group: String? = nil, keywords: [String] = [], color: Color? = nil, isEnabled: Bool = true, variants: [Self] = []) {
        // Store what we're given - will be filled by protocol extension if needed
        if let id = id {
            self.id = id
            self.name = name ?? Self.humanReadable(from: id.rawValue)
        } else if let name = name {
            self.id = ID(Self.kebabCase(name))
            self.name = name
        } else {
            // Both nil - will be filled by filledMetadata
            self.id = ID("")
            self.name = ""
        }
        self.systemImage = systemImage
        self.description = description
        self.group = group
        self.keywords = keywords
        self.color = color
        self.isEnabled = isEnabled
        self.variants = variants
    }
    
    public init<T: DemoView>(type: T.Type, id: ID? = nil, name: String? = nil, systemImage: String = "puzzlepiece", description: String? = nil, group: String? = nil, keywords: [String] = [], color: Color? = nil, isEnabled: Bool = true, variants: [Self] = []) {
        let (finalName, finalID) = Self.computeNameAndID(type: type, name: name, id: id?.rawValue)
        self.id = ID(finalID)
        self.name = finalName
        self.systemImage = systemImage
        self.description = description
        self.group = group
        self.keywords = keywords
        self.color = color
        self.isEnabled = isEnabled
        self.variants = variants
    }
}

public protocol DemoView: View {
    static var metadata: DemoMetadata { get }

    @MainActor
    init()
}

public extension DemoView {
    static var filledMetadata: DemoMetadata {
        var meta = metadata
        
        // If name or id is empty, compute from type
        if meta.name.isEmpty || meta.id.rawValue.isEmpty {
            let (name, id) = DemoMetadata.computeNameAndID(
                type: Self.self,
                name: meta.name.isEmpty ? nil : meta.name,
                id: meta.id.rawValue.isEmpty ? nil : meta.id.rawValue
            )
            
            if meta.name.isEmpty {
                meta.name = name
            }
            if meta.id.rawValue.isEmpty {
                meta.id = DemoMetadata.ID(id)
            }
        }
        
        return meta
    }
    
    static var defaultMetadata: DemoMetadata {
        let typeName = String(describing: Self.self)
        var cleanedTypeName = typeName
        
        // Only strip suffixes
        if cleanedTypeName.hasSuffix("DemoView") {
            cleanedTypeName = String(cleanedTypeName.dropLast(8))
        } else if cleanedTypeName.hasSuffix("Demo") {
            cleanedTypeName = String(cleanedTypeName.dropLast(4))
        } else if cleanedTypeName.hasSuffix("View") {
            cleanedTypeName = String(cleanedTypeName.dropLast(4))
        }
        cleanedTypeName = cleanedTypeName.trimmingCharacters(in: .whitespaces)
        
        let finalName = cleanedTypeName.isEmpty ? typeName : cleanedTypeName
        
        return DemoMetadata(
            id: DemoMetadata.ID(DemoMetadata.kebabCase(finalName)),
            name: DemoMetadata.humanReadable(from: finalName)
        )
    }
}

extension DemoMetadata {
    static func computeNameAndID<T>(type: T.Type, name: String?, id: String?) -> (name: String, id: String) {
        if let name = name, let id = id {
            return (name: name, id: id)
        } else if let id = id {
            return (name: humanReadable(from: id), id: id)
        } else if let name = name {
            return (name: name, id: kebabCase(name))
        } else {
            // Derive from type name
            let typeName = String(describing: type)
            var cleanedTypeName = typeName
            
            // Only strip suffixes
            if cleanedTypeName.hasSuffix("DemoView") {
                cleanedTypeName = String(cleanedTypeName.dropLast(8))
            } else if cleanedTypeName.hasSuffix("Demo") {
                cleanedTypeName = String(cleanedTypeName.dropLast(4))
            } else if cleanedTypeName.hasSuffix("View") {
                cleanedTypeName = String(cleanedTypeName.dropLast(4))
            }
            cleanedTypeName = cleanedTypeName.trimmingCharacters(in: .whitespaces)
            
            let finalName = cleanedTypeName.isEmpty ? typeName : cleanedTypeName
            return (name: humanReadable(from: finalName), id: kebabCase(finalName))
        }
    }
    
    static func kebabCase(_ string: String) -> String {
        // Convert to kebab-case: "My Demo View" -> "my-demo-view"
        string
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            // Handle camelCase/PascalCase
            .replacingOccurrences(of: "([A-Z])", with: "-$1", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .lowercased()
    }
    
    static func humanReadable(from string: String) -> String {
        // Convert from kebab-case or camelCase to human readable
        let fromKebab = string.replacingOccurrences(of: "-", with: " ")
        let fromCamel = fromKebab.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
        return fromCamel
            .trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

// protocol DemoScene: Scene {
//    static var metadata: DemoMetadata { get }
//
//    @MainActor
//    init()
// }

let logger: Logger? = Logger(subsystem: "DemoKit", category: "DemoKit")
