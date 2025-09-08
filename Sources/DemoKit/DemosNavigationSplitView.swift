import SwiftUI
import OSLog

struct DemosNavigationSplitView: View {
    @Bindable var viewModel: DemoPickerViewModel

    init(viewModel: DemoPickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let elements = viewModel.demos.map { (type: $0, metadata: $0.metadata) }
        
        let grouped = Dictionary(grouping: elements) { $0.metadata.group }
        let sortedGroups = grouped.keys.compactMap { $0 }.sorted()
        let ungroupedElements = grouped[nil] ?? []
        
        NavigationSplitView {
            List(selection: $viewModel.selection) {
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
            if let id = viewModel.selection,
               let element = elements.first(where: { $0.metadata.id == id }) {
                AnyView(element.type.init()).id(id)
            } else {
                Text("Select a demo from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: viewModel.selection) { oldValue, newValue in
            guard oldValue != newValue else { return }
            logger?.debug("Selection changed from '\(oldValue?.rawValue ?? "nil")' to '\(newValue?.rawValue ?? "nil")'")
            viewModel.selectionDidChange()
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