import Foundation
@_implementationOnly import os
@_implementationOnly import RegexBuilder
import SwiftUI
#if os(macOS)
@_implementationOnly import AppKit
#endif
@_implementationOnly import AsyncAlgorithms

private let logger: Logger? = nil // Logger(subsystem: "TODO", category: "TODO")

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
    
    let unstableTime: TimeInterval
    let showLifeCycle: Bool
    
    public init(unstableTime: TimeInterval = 0.5, showLifeCycle: Bool = false, @DemosBuilder _ demos: () -> [AnyDemo]) {
        self.unstableTime = unstableTime
        self.showLifeCycle = showLifeCycle
        model.demos = demos()
    }
    
    public init(unstableTime: TimeInterval = 0.5, showLifeCycle: Bool = false, _ demos: [AnyDemo]) {
        self.unstableTime = unstableTime
        self.showLifeCycle = showLifeCycle
        model.demos = demos
    }
    
    public var body: some View {
        NavigationSplitView {
#if os(macOS)
            List(selection: $sidebarSelection) {
                ForEach(filteredDemos) { demo in
                    DemoRow(demo: demo, metadata: model.demoMetadata[demo.id]!)
                }
            }
            .searchable(text: $searchText, placement: .sidebar, prompt: "search…")
#endif
        } detail: {
            if let demo = model.allDemos[sidebarSelection] {
                CrashDetectionView(id: demo.id, unstableTime: unstableTime, showLifeCycle: showLifeCycle) { crash in
                    var tags = model.demoMetadata[demo.id]!.tags
                    switch crash {
                    case .potential:
                        tags.insert("Crashed")
                    case .unknown:
                        tags.remove("Crashed")
                    }
                    model.demoMetadata[demo.id]!.tags = tags
                }
                content: {
                    DemoView(demo: demo)
                }
                .id(demo.id)
            }
        }
        .environmentObject(model)
        .onChange(of: scenePhase) { scenePhase in
            logger?.log("\(String(describing: scenePhase))")
        }
#if os(macOS)
        //        .task {
        //            do {
        //                let n = NotificationCenter.default.notifications(named: NSApplication.willTerminateNotification)
        //                for try await x in n {
        //                    logger?.log("\(x)")
        //                }
        //            }
        //            catch {
        //            }
        //        }
#endif
    }
}

internal struct DemoView: View {
    @EnvironmentObject
    var model: DemoModel
    
    let demo: AnyDemo
    
    var body: some View {
        demo.body
    }
}

internal struct DemoRow: View {
    @EnvironmentObject
    var model: DemoModel
    
    let demo: AnyDemo
    
    @State
    var metadataDisplayed = false
    
    @State
    var metadata: DemoMetadata
    
    var body: some View {
        HStack {
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
        .onChange(of: metadata) { _ in
            model.demoMetadata[demo.id] = metadata
        }
    }
}
