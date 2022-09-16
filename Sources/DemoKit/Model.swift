import Foundation
@_implementationOnly import os
@_implementationOnly import RegexBuilder
import SwiftUI
#if os(macOS)
@_implementationOnly import AppKit
#endif
@_implementationOnly import AsyncAlgorithms

private let logger: Logger? = nil // Logger(subsystem: "TODO", category: "TODO")

public protocol Demo: Identifiable {
    associatedtype Content where Content: View
    var id: String { get }
    var title: String { get }
    var body: Content { get }
    var tags: Set<String> { get }
}

public extension Demo {
    var tags: Set <String> {
        return []
    }
}

public struct AnyDemo: Demo {
    public let id: String
    public let title: String
    public let tags: Set <String>
    let view: () -> AnyView

    public init<Base>(_ base: Base, extraTags: Set<String> = []) where Base: Demo {
        id = base.id
        title = base.title
        view = {
            AnyView(base.body)
        }
        tags = base.tags.union(extraTags)
    }

    public var body: some View {
        view()
    }
}

public extension AnyDemo {
    init<Content>(_ title: String, tags: Set<String> = [], @ViewBuilder body: @escaping () -> Content) where Content: View {
        id = title
        self.title = title
        self.tags = tags
        view = {
            AnyView(body())
        }
    }

    init<Content>(tags: Set<String> = [], @ViewBuilder body: @escaping () -> Content) where Content: View {
        self.id = String(describing: Content.self)
        self.title = String(describing: Content.self)
        self.tags = tags
        view = {
            AnyView(body())
        }
    }
}

public extension Demo {
    func tagged(_ tags: Set<String>) -> some Demo {
        return AnyDemo(self, extraTags: tags)
    }
    
    func grouped(_ group: String) -> some Demo {
        var tags = self.tags.filter({ $0.hasPrefix("group") == false })
        tags.insert("group:\(group)")
        return tagged(tags)
    }
}

public struct DemoMetadata: Equatable, Codable {
    public let demo: String
    public var tags: Set<String>
    public var comments: String
}

public extension DemoMetadata {
    var starred: Bool {
        get {
            tags.contains("starred")
        }
        set {
            if newValue {
                tags.insert("starred")
            } else {
                tags.remove("starred")
            }
        }
    }
    
    var crashed: Bool {
        get {
            tags.contains("crashed")
        }
        set {
            if newValue {
                tags.insert("crashed")
            } else {
                tags.remove("crashed")
            }
        }
    }
}

@resultBuilder
public enum DemosBuilder {
    public static func buildBlock(_ components: any Demo...) -> [AnyDemo] {
        components.map { AnyDemo($0) }
    }
}

// MARK: Internal Model

class DemoModel: ObservableObject {
    @Published
    var allDemos: [String: AnyDemo] = [:]

    @Persistent(url: FileManager().applicationSupportDirectory.appending(path: "test.json"))
    var demoMetadata: [String: DemoMetadata] = [:]
}

extension DemoModel {
    convenience init(@DemosBuilder _ demos: () -> [AnyDemo]) {
        let demos = demos()
        self.init()
        for demo in demos {
            allDemos[demo.id] = demo
            demoMetadata[demo.id] = .init(demo: demo.id, tags: [], comments: "")
        }
    }

    var demos: [AnyDemo] {
        get {
            Array(allDemos.values)
        }
        set {
            for demo in newValue {
                allDemos[demo.id] = demo
                if demoMetadata[demo.id] == nil {
                    demoMetadata[demo.id] = .init(demo: demo.id, tags: [], comments: "")
                }
            }
        }
    }
}
