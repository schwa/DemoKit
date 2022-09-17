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
    
    var groups: [Group] {
        let groupNames = Set(filteredDemos.compactMap {
            $0.tags.first(where: { $0.hasPrefix("group:") })?.trimmingPrefix("group:")
        })
        return groupNames.map { groupName in
            let groupName = String(groupName)
            return Group(id: groupName, title: groupName, children: filteredDemos.filter { $0.tags.contains("group:\(groupName)") })
        }
    }
    
    struct Group: Identifiable {
        let id: String
        let title: String
        let children: [AnyDemo]?
    }
    
    public init(unstableTime: TimeInterval = 0.5, showLifeCycle: Bool = false, _ demos: [AnyDemo]) {
        self.unstableTime = unstableTime
        self.showLifeCycle = showLifeCycle
        model.demos = demos
    }
    
    public init(unstableTime: TimeInterval = 0.5, showLifeCycle: Bool = false, @DemosBuilder _ demos: () -> [AnyDemo]) {
        self = DemosView(unstableTime: unstableTime, showLifeCycle: showLifeCycle, demos())
    }
    
    public var body: some View {
        NavigationSplitView(sidebar: { sidebar }, detail: { detail })
        .environmentObject(model)
        .onChange(of: scenePhase) { scenePhase in
            logger?.log("\(String(describing: scenePhase))")
        }
    }
    
    @ViewBuilder
    var sidebar: some View {
        List(selection: $sidebarSelection) {
            ForEach(groups) { group in
                Section(group.title) {
                    ForEach(group.children ?? []) { demo in
                        DemoRow(demo: demo, metadata: model.demoMetadata[demo.id]!)
                        
                    }
                    
                }
                
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "search…")
    }
    
    @ViewBuilder
    var detail: some View {
        if let demo = model.allDemos[sidebarSelection] {
            CrashDetectionView(id: demo.id, unstableTime: unstableTime, showLifeCycle: showLifeCycle) { crash in
                var tags = model.demoMetadata[demo.id]!.tags
                switch crash {
                case .potential:
                    tags.insert("crashed")
                case .unknown:
                    tags.remove("crashed")
                }
                model.demoMetadata[demo.id]!.tags = tags
            }
        content: {
            DemoView(demo: demo)
        }
        .id(demo.id)
        }
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
            if metadata.crashed {
                Image(systemName: "exclamationmark.triangle").foregroundColor(Color.red)
            }
            
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
