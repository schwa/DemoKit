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
        if let id {
            self.id = id
            self.name = name ?? Self.humanReadable(from: id.rawValue)
        } else if let name {
            self.id = ID(Self.kebabCase(name))
            self.name = name
        } else {
            fatalError("DemoMetadata must have either a name or an id")
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

// swiftlint:disable no_grouping_extension superfluous_else
extension DemoMetadata {
    static func computeNameAndID<T>(type: T.Type, name: String?, id: String?) -> (name: String, id: String) {
        if let name, let id {
            return (name: name, id: id)
        } else if let id {
            return (name: humanReadable(from: id), id: id)
        } else if let name {
            return (name: name, id: kebabCase(name))
        } else {
            let typeName = String(describing: type)
            var cleanedTypeName = typeName

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
        string
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: "([A-Z])", with: "-$1", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .lowercased()
    }

    static func humanReadable(from string: String) -> String {
        let fromKebab = string.replacingOccurrences(of: "-", with: " ")
        let fromCamel = fromKebab
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .replacingOccurrences(of: "([0-9]+)", with: " $1", options: .regularExpression)
        return fromCamel
            .trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
// swiftlint:enable no_grouping_extension superfluous_else

// protocol DemoScene: Scene {
//    static var metadata: DemoMetadata { get }
//
//    @MainActor
//    init()
// }

let logger: Logger? = Logger(subsystem: "DemoKit", category: "DemoKit")
