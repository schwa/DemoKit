import SwiftUI

struct DemosNavigationSplitView: View {
    private let demos: [any DemoView.Type]

    @AppStorage("demoview")
    private var storedSelection: String = ""
    
    @State
    private var selection: DemoMetadata.ID?

    init(demos: [any DemoView.Type]) {
        self.demos = demos
    }

    var body: some View {
        let elements = demos.map { (type: $0, metadata: $0.metadata) }
        
        let grouped = Dictionary(grouping: elements) { $0.metadata.group }
        let sortedGroups = grouped.keys.compactMap { $0 }.sorted()
        let ungroupedElements = grouped[nil] ?? []
        
        NavigationSplitView {
            List(selection: $selection) {
                if !ungroupedElements.isEmpty {
                    ForEach(ungroupedElements, id: \.metadata.id) { type, metadata in
                        navigationLink(for: metadata)
                    }
                }
                
                ForEach(sortedGroups, id: \.self) { group in
                    Section(group) {
                        ForEach(grouped[group] ?? [], id: \.metadata.id) { type, metadata in
                            navigationLink(for: metadata)
                        }
                    }
                }
            }
        } detail: {
            if let id = selection, let element = elements.first(where: { $0.metadata.id == id }) {
                AnyView(element.type.init()).id(id)
            }
        }
        .onAppear {
            print("ON APPEAR: \(selection)")
            guard selection == nil else {
                return
            }
            // First check environment variable
            if let envSelection = ProcessInfo.processInfo.environment["DEMOVIEW"], !envSelection.isEmpty {
                print(envSelection)
                let envID = DemoMetadata.ID(envSelection)
                if elements.contains(where: { $0.metadata.id == envID }) {
                    selection = envID
                    return
                }
            }

            // Then check stored selection
            if !storedSelection.isEmpty {
                let storedID = DemoMetadata.ID(storedSelection)
                if elements.contains(where: { $0.metadata.id == storedID }) {
                    selection = storedID
                } else {
                    selection = elements.first?.metadata.id
                }
            } else {
                selection = elements.first?.metadata.id
            }
        }
        .onChange(of: selection) {
            storedSelection = selection?.rawValue ?? ""
        }
    }

    func navigationLink(for metadata: DemoMetadata) -> some View {
        NavigationLink(value: metadata.id) {
            VStack(alignment: .leading) {
                HStack {
                    Label(metadata.name, systemImage: metadata.systemImage)
                        .layoutPriority(1)
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .foregroundStyle(metadata.color ?? Color.primary)
                        .labelStyle(.titleAndIcon)
                    KeywordsView(keywords: metadata.keywords)
                }
                if let description = metadata.description {
                    Text(description)
                        .lineLimit(nil)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

//extension View {
//
//    func foo() -> some View {
//        self.onOpenURL { url in
//            let id = DemoMetadata.ID(url.lastPathComponent)
//            guard elements.contains(where: { $0.metadata.id == id }) else {
//                return
//            }
////            selection = id
//        }
//
//    }
//
//}
