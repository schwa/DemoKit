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
        self.id = id ?? ID(name)
        self.name = name
        self.systemImage = systemImage
        self.description = description
        self.group = group
        self.keywords = keywords
        self.color = color
        self.isEnabled = isEnabled
        self.variants = variants
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

//protocol DemoScene: Scene {
//    static var metadata: DemoMetadata { get }
//
//    @MainActor
//    init()
//}

let logger: Logger? = Logger(subsystem: "DemoKit", category: "DemoKit")
