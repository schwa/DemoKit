import SwiftUI
import OSLog

private extension View {
    @ViewBuilder
    func applySearchable(searchText: Binding<String>, shouldShow: Bool) -> some View {
        if shouldShow {
            self.searchable(text: searchText, placement: .sidebar, prompt: "Search Demos")
        } else {
            self
        }
    }
}

struct DemosNavigationSplitView: View {
    @Bindable
    var viewModel: DemoPickerViewModel

    @State
    var searchText: String = ""

    init(viewModel: DemoPickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let elements = viewModel.demos.map { (type: $0, metadata: $0.metadata) }
        
        // Filter elements based on search text
        let filteredElements = searchText.isEmpty ? elements : elements.filter { element in
            let metadata = element.metadata
            let searchLower = searchText.lowercased()
            
            // Search in title
            if metadata.name.lowercased().contains(searchLower) {
                return true
            }
            
            // Search in description
            if let description = metadata.description,
               description.lowercased().contains(searchLower) {
                return true
            }
            
            // Search in keywords
            if metadata.keywords.contains(where: { $0.lowercased().contains(searchLower) }) {
                return true
            }
            
            return false
        }
        
        let grouped = Dictionary(grouping: filteredElements) { $0.metadata.group }
        let sortedGroups = grouped.keys.compactMap { $0 }.sorted()
        let ungroupedElements = grouped[nil] ?? []
        
        NavigationSplitView {
            List(selection: $viewModel.selection) {
                if filteredElements.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    if !ungroupedElements.isEmpty {
                        ForEach(ungroupedElements, id: \.metadata.id) { element in
                            navigationLink(for: element.metadata)
                        }
                    }
                    
                    ForEach(sortedGroups, id: \.self) { group in
                        Section(group) {
                            ForEach(grouped[group] ?? [], id: \.metadata.id) { element in
                                navigationLink(for: element.metadata)
                            }
                        }
                    }
                }
            }
            .id(searchText) // Force List to update when search changes
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
        .applySearchable(searchText: $searchText, shouldShow: elements.count >= 6)
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
        .help("Name: \(metadata.name)\nID: \(metadata.id.rawValue)\(metadata.description.map { "\nDescription: \($0)" } ?? "")")
    }
}
