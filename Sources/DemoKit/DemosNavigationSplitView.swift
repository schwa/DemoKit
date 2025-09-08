import SwiftUI

private extension View {
    @ViewBuilder
    func applySearchable(searchText: Binding<String>, shouldShow: Bool) -> some View {
        if shouldShow {
            self.searchable(text: searchText, placement: .sidebar, prompt: "Search Demos")
        }
        else {
            self
        }
    }
}

struct DemosNavigationSplitView: View {
    @Environment(DemoPickerViewModel.self)
    private var viewModel: DemoPickerViewModel

    @State
    private var searchText: String = ""

    var body: some View {
        let elements = viewModel.demos.map { (type: $0, metadata: $0.metadata) }

        let filteredElements = searchText.isEmpty ? elements : elements.filter { element in
            let metadata = element.metadata
            let searchLower = searchText.lowercased()

            if metadata.name.lowercased().contains(searchLower) {
                return true
            }

            if let description = metadata.description,
               description.lowercased().contains(searchLower) {
                return true
            }

            if metadata.keywords.contains(where: { $0.lowercased().contains(searchLower) }) {
                return true
            }

            return false
        }

        let pinnedElements = filteredElements.filter { viewModel.isPinned($0.metadata.id) }
        let unpinnedElements = filteredElements.filter { !viewModel.isPinned($0.metadata.id) }
        
        let grouped = Dictionary(grouping: unpinnedElements) { $0.metadata.group }
        let sortedGroups = grouped.keys.compactMap(\.self).sorted()
        let ungroupedElements = grouped[nil] ?? []

        NavigationSplitView {
            @Bindable
            var viewModel = viewModel

            List(selection: $viewModel.selection) {
                if filteredElements.isEmpty, !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
                else {
                    if !pinnedElements.isEmpty {
                        Section("Pinned") {
                            ForEach(pinnedElements, id: \.metadata.id) { element in
                                navigationLink(for: element.metadata, showPinIcon: true)
                            }
                        }
                    }
                    
                    if !ungroupedElements.isEmpty {
                        ForEach(ungroupedElements, id: \.metadata.id) { element in
                            navigationLink(for: element.metadata, showPinIcon: false)
                        }
                    }

                    ForEach(sortedGroups, id: \.self) { group in
                        Section(group) {
                            ForEach(grouped[group] ?? [], id: \.metadata.id) { element in
                                navigationLink(for: element.metadata, showPinIcon: false)
                            }
                        }
                    }
                }
            }
            .id(searchText)
        } detail: {
            if let id = viewModel.selection,
               let element = elements.first(where: { $0.metadata.id == id }) {
                AnyView(element.type.init()).id(id)
            }
            else {
                Text("Select a demo from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: viewModel.selection) { oldValue, newValue in
            guard oldValue != newValue else { return }
            viewModel.selectionDidChange()
        }
        .applySearchable(searchText: $searchText, shouldShow: elements.count >= 6)
    }

    func navigationLink(for metadata: DemoMetadata, showPinIcon: Bool) -> some View {
        NavigationLink(value: metadata.id) {
            VStack(alignment: .leading) {
                HStack {
                    if showPinIcon {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.tint)
                            .imageScale(.small)
                    }
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
        .contextMenu {
            Button(viewModel.isPinned(metadata.id) ? "Unpin" : "Pin") {
                viewModel.togglePin(for: metadata.id)
            }
        }
        .help("Name: \(metadata.name)\nID: \(metadata.id.rawValue)\(metadata.description.map { "\nDescription: \($0)" } ?? "")")
    }
}
