import SwiftUI
import Foundation
import RegexBuilder
import os
#if os(macOS)
import AppKit
#endif
import AsyncAlgorithms

let logger = Logger(subsystem: "TODO", category: "TODO")

// MARK: Model

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

    public init <Base>(_ base: Base) where Base: Demo {
        self.id = base.id
        self.title = base.title
        self.view = {
            AnyView(base.body)
        }
    }

    public var body: some View {
        return view()
    }
}

public extension AnyDemo {
    init <Content>(_ title: String, @ViewBuilder body: @escaping () -> Content) where Content: View {
        self.id = title
        self.title = title
        self.view = {
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
            return tags.contains("starred")
        }
        set {
            if newValue {
                logger.log("INSERTING")
                tags.insert("starred")
            }
            else {
                logger.log("REMOVING")
                tags.remove("starred")
            }

        }
    }
}

@resultBuilder
public struct DemosBuilder {
    public static func buildBlock(_ components: any Demo...) -> [AnyDemo] {
        return components.map { AnyDemo($0) }
    }
}

// MARK: Internal Model

class DemoModel: ObservableObject {

    @Published
    var allDemos: [String: AnyDemo] = [:]

    @Published
    //    var demoMetadata: [String: DemoMetadata] = [:]
    var demoMetadata = try! MiniDatabase<DemoMetadata>(url: FileManager().applicationSupportDirectory.appending(path: "test.journal"))
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
            return Array(allDemos.values)
        }
        set {
            for demo in newValue {
                allDemos[demo.id] = demo
                demoMetadata[demo.id] = .init(demo: demo.id, tags: [], comments: "")
            }
        }
    }
}


// MARK: Views

public struct DemosView: View {

    @Environment(\.scenePhase)
    var scenePhase

    var model = DemoModel()

    @AppStorage("selectedDemo") // TODO: Should be SceneStorage
    var sidebarSelection: String = ""

    @State
    var searchText: String = ""

    var filteredDemos: [AnyDemo] {
        let pattern = Regex { searchText }.ignoresCase()
        return Array(model.allDemos.values
            .filter { searchText.isEmpty || $0.title.contains(pattern) }
            .sorted(using: MySortComparator(\.title)))
    }

    public init(@DemosBuilder _ demos: () -> [AnyDemo]) {
        model.demos = demos()
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $sidebarSelection) {
                ForEach(filteredDemos) { demo in
                    DemoRow(demo: demo, metadata: model.demoMetadata[demo.id]!)
                }
            }
            .searchable(text: $searchText, placement: .sidebar, prompt: "search…")
        } detail: {
            if let demo = model.allDemos[sidebarSelection] {
                CrashDetectionView(id: demo.id, showLifeCycle: true) {
                    DemoView(demo: demo)
                }
                .id(demo.id)
            }
        }
        .environmentObject(model)
        .onChange(of: scenePhase) { scenePhase in
            logger.log("\(String(describing: scenePhase))")
        }
#if os(macOS)
        //        .task {
        //            do {
        //                let n = NotificationCenter.default.notifications(named: NSApplication.willTerminateNotification)
        //                for try await x in n {
        //                    logger.log("\(x)")
        //                }
        //            }
        //            catch {
        //            }
        //        }
#endif
    }
}

struct DemoView: View {
    @EnvironmentObject
    var model: DemoModel

    let demo: AnyDemo

    var body: some View {
        demo.body
    }
}

// TODO: Doesn't wor
struct DemoRow: View {

    @EnvironmentObject
    var model: DemoModel

    let demo: AnyDemo

    @State
    var metadataDisplayed = false

    @State
    var metadata: DemoMetadata

    var body: some View {
        return HStack {
            Toggle("Star", isOn: $metadata.starred)
                .toggleStyle(MyToggleStyle(on: "star.fill", off: "star"))
            Text(demo.title)
            Spacer()
            Button {
                metadataDisplayed = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $metadataDisplayed) {
                let metadata = model.demoMetadata[demo.id]! // TODO: Bang
                Form {
                    LabeledContent("ID", value: demo.id)
                    LabeledContent("Title", value: demo.title)
                    LabeledContent("Tags", value: metadata.tags.joined(separator: ", ")) // TODO: list format
                    LabeledContent("Comments") {
                        TextField("comment", text: $metadata.comments)
                    }
                }
                .padding()
            }
        }
        .onChange(of: metadata) { newValue in
            model.demoMetadata[demo.id] = metadata
        }
    }
}

