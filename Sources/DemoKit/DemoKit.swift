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

    public init(id: ID? = nil, name: String, systemImage: String = "puzzlepiece", description: String? = nil, group: String? = nil, keywords: [String] = [], color: Color? = nil, isEnabled: Bool = true, variants: [Self] = []) {
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

public protocol DemoView: View {
    static var metadata: DemoMetadata { get }

    @MainActor
    init()
}

// protocol DemoScene: Scene {
//    static var metadata: DemoMetadata { get }
//
//    @MainActor
//    init()
// }

let logger: Logger? = Logger(subsystem: "DemoKit", category: "DemoKit")
