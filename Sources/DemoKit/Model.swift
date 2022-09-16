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
}

public struct AnyDemo: Demo {
    public let id: String
    public let title: String
    let view: () -> AnyView

    public init<Base>(_ base: Base) where Base: Demo {
        id = base.id
        title = base.title
        view = {
            AnyView(base.body)
        }
    }

    public var body: some View {
        view()
    }
}

public extension AnyDemo {
    init<Content>(_ title: String, @ViewBuilder body: @escaping () -> Content) where Content: View {
        id = title
        self.title = title
        view = {
            AnyView(body())
        }
    }

    init<Content>(@ViewBuilder body: @escaping () -> Content) where Content: View {
        self.id = String(describing: Content.self)
        self.title = String(describing: Content.self)
        view = {
            AnyView(body())
        }
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
                logger?.log("INSERTING")
                tags.insert("starred")
            } else {
                logger?.log("REMOVING")
                tags.remove("starred")
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
