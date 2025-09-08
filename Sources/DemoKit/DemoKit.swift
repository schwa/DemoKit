import SwiftUI
internal import os

public struct DemoMetadata: Identifiable, Sendable {
    public var id: ID
    public var name: String
    public var systemImage: String
    public var description: String?
    public var group: String?
    public var keywords: [String]
    public var color: Color?
    public var isEnabled: Bool
    public var variants: [DemoMetadata] = []

    public struct ID: Hashable, Sendable {
        public var rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public init(id: ID? = nil, name: String, systemImage: String = "puzzlepiece", description: String? = nil, group: String? = nil, keywords: [String] = [], color: Color? = nil, isEnabled: Bool = true, variants: [DemoMetadata] = []) {
        self.id = id ?? ID(Self.kebabCase(name))
        self.name = name
        self.systemImage = systemImage
        self.description = description
        self.group = group
        self.keywords = keywords
        self.color = color
        self.isEnabled = isEnabled
        self.variants = variants
    }
    
    private static func kebabCase(_ string: String) -> String {
        // Convert to kebab-case: "My Demo View" -> "my-demo-view"
        string
            .replacingOccurrences(of: "DemoView", with: "")
            .replacingOccurrences(of: "Demo View", with: "")
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
    }
}

//let defaultName = "\(type(of: Self.self))"
//    .replacingOccurrences(of: ".Type", with: "")
//    .replacingOccurrences(of: "DemoView", with: "")


public protocol DemoView: View {
    static var metadata: DemoMetadata { get }

    @MainActor
    init()
}

public extension DemoView {
    // Helper to create metadata with automatic ID generation from type name
    static func makeMetadata(
        id: DemoMetadata.ID? = nil,
        name: String? = nil,
        systemImage: String = "puzzlepiece",
        description: String? = nil,
        group: String? = nil,
        keywords: [String] = [],
        color: Color? = nil,
        isEnabled: Bool = true,
        variants: [DemoMetadata] = []
    ) -> DemoMetadata {
        let typeName = String(describing: Self.self)
        
        // Generate default name from type name: "MyDemoView" -> "My Demo View"
        let defaultName = name ?? typeName
            .replacingOccurrences(of: "DemoView", with: "")
            .replacingOccurrences(of: "Demo", with: "")
            .reduce("") { result, char in
                if char.isUppercase && !result.isEmpty {
                    return result + " " + String(char)
                }
                return result + String(char)
            }
            .trimmingCharacters(in: .whitespaces)
        
        // Generate default ID from type name in kebab-case
        let defaultID = id ?? DemoMetadata.ID(
            typeName
                .replacingOccurrences(of: "DemoView", with: "")
                .replacingOccurrences(of: "Demo", with: "")
                .reduce("") { result, char in
                    if char.isUppercase && !result.isEmpty {
                        return result + "-" + String(char).lowercased()
                    }
                    return result + String(char).lowercased()
                }
        )
        
        return DemoMetadata(
            id: defaultID,
            name: defaultName,
            systemImage: systemImage,
            description: description,
            group: group,
            keywords: keywords,
            color: color,
            isEnabled: isEnabled,
            variants: variants
        )
    }
}

//protocol DemoScene: Scene {
//    static var metadata: DemoMetadata { get }
//
//    @MainActor
//    init()
//}

let logger: Logger? = Logger(subsystem: "DemoKit", category: "DemoKit")
