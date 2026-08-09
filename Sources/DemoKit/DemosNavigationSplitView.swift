import SwiftUI

struct DemosNavigationSplitView: View { // swiftlint:disable:this type_body_length
    @Environment(DemoPickerViewModel.self)
    private var viewModel: DemoPickerViewModel

    @Environment(\.demoKitConfiguration)
    private var configuration: DemoKitConfiguration

    @State
    private var searchText: String = ""

    @State
    private var hoveredID: DemoMetadata.ID?

    @State
    private var selectedKeyword: String?

    private var visibleElements: [(type: any DemoView.Type, metadata: DemoMetadata)] {
        viewModel.demos
            .map { (type: $0, metadata: $0.metadata) }
            .filter { !viewModel.isHidden($0.metadata.id) }
    }

    private var filteredElements: [(type: any DemoView.Type, metadata: DemoMetadata)] {
        guard !searchText.isEmpty || selectedKeyword != nil else { return visibleElements }

        return visibleElements.filter { element in
            DemoFilter.matches(element.metadata, searchText: searchText, keyword: selectedKeyword)
        }
    }

    private func toggleKeywordFilter(_ keyword: String) {
        if selectedKeyword?.caseInsensitiveCompare(keyword) == .orderedSame {
            selectedKeyword = nil
        }
        else {
            selectedKeyword = keyword
        }
    }

    private var pinnedElements: [(type: any DemoView.Type, metadata: DemoMetadata)] {
        filteredElements.filter { viewModel.isPinned($0.metadata.id) }
    }

    private var unpinnedElements: [(type: any DemoView.Type, metadata: DemoMetadata)] {
        filteredElements.filter { !viewModel.isPinned($0.metadata.id) }
    }

    private var groupedElements: [String?: [(type: any DemoView.Type, metadata: DemoMetadata)]] {
        Dictionary(grouping: unpinnedElements) { $0.metadata.group }
    }

    private var sortedGroups: [String] {
        groupedElements.keys.compactMap(\.self).sorted()
    }

    private var ungroupedElements: [(type: any DemoView.Type, metadata: DemoMetadata)] {
        groupedElements[nil] ?? []
    }

    @State
    private var hasConfiguration = false

    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    var body: some View {
        NavigationSplitView {
            demoList
        } detail: {
            detailView
        }
        .onChange(of: viewModel.selection) { oldValue, newValue in
            guard oldValue != newValue else { return }
            viewModel.selectionDidChange()
        }
        .applySearchable(searchText: $searchText, shouldShow: visibleElements.count >= 6)
    }

    @ViewBuilder
    private var demoList: some View {
        @Bindable var viewModel = viewModel

        List(selection: $viewModel.selection) {
            if let selectedKeyword {
                keywordFilterBanner(for: selectedKeyword)
            }
            listContent
        }
        .id(searchText)
        .contextMenu {
            if !viewModel.hiddenDemoIDs.isEmpty {
                Button {
                    viewModel.unhideAll()
                } label: {
                    Label("Unhide All Demos (\(viewModel.hiddenDemoIDs.count))", systemImage: "eye")
                }
            }
        }
    }

    private func keywordFilterBanner(for keyword: String) -> some View {
        HStack {
            Label("Filtered by \(keyword)", systemImage: "line.3.horizontal.decrease.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Clear") {
                selectedKeyword = nil
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .accessibilityIdentifier("clear-keyword-filter")
        }
        .selectionDisabled()
    }

    @ViewBuilder
    private var listContent: some View {
        if filteredElements.isEmpty, selectedKeyword != nil {
            ContentUnavailableView {
                Label("No Matching Demos", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("No demos match the current filter")
            } actions: {
                Button("Clear Filter") {
                    selectedKeyword = nil
                }
            }
        }
        else if filteredElements.isEmpty, !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
        else if visibleElements.isEmpty, !viewModel.hiddenDemoIDs.isEmpty {
            allDemosHiddenView
        }
        else {
            demosContent
        }
    }

    @ViewBuilder
    private var demosContent: some View {
        if !pinnedElements.isEmpty {
            Section("Pinned") {
                ForEach(pinnedElements, id: \.metadata.id) { element in
                    navigationLink(for: element.metadata)
                }
            }
        }

        if !ungroupedElements.isEmpty {
            ForEach(ungroupedElements, id: \.metadata.id) { element in
                navigationLink(for: element.metadata)
            }
        }

        ForEach(sortedGroups, id: \.self) { group in
            Section(group) {
                ForEach(groupedElements[group] ?? [], id: \.metadata.id) { element in
                    navigationLink(for: element.metadata)
                }
            }
        }
    }

    @ViewBuilder
    private var allDemosHiddenView: some View {
        ContentUnavailableView {
            Label("All Demos Hidden", systemImage: "eye.slash")
        } description: {
            Text("\(viewModel.hiddenDemoIDs.count) demo\(viewModel.hiddenDemoIDs.count == 1 ? " is" : "s are") hidden")
        } actions: {
            Button("Unhide All") {
                viewModel.unhideAll()
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let id = viewModel.selection,
           let element = visibleElements.first(where: { $0.metadata.id == id }) {
            let demoView = AnyView(element.type.init())
            ZStack {
                Color.clear
                DemoDescriptionContainer(
                    metadata: element.metadata,
                    content: demoView
                )
            }
            .clipped()
            .onPreferenceChange(HasDemoConfigurationPreferenceKey.self) { value in
                hasConfiguration = value
                if !value {
                    showConfiguration = false
                }
            }
            .toolbar {
                if hasConfiguration {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showConfiguration.toggle()
                        } label: {
                            Label("Configuration", systemImage: "gear")
                        }
                        .help("Toggle configuration panel")
                        .accessibilityIdentifier("toggle-configuration")
                    }
                }
            }
            .id(id)
            .navigationTitle("\(element.metadata.name)")
            .onChange(of: viewModel.screenshotRequest) { _, request in
                guard let request else { return }
                viewModel.screenshotRequest = nil
                takeScreenshot(of: demoView, demoID: element.metadata.id.rawValue, options: request)
            }
        } else {
            ContentUnavailableView("Select a Demo", systemImage: "sidebar.left", description: Text("Choose a demo from the sidebar"))
        }
    }

    private func takeScreenshot<V: View>(of view: V, demoID: String, options: ScreenshotOptions) {
        let renderer = ImageRenderer(
            content: view
                .frame(width: options.width, height: options.height)
                .background(options.background)
        )
        renderer.scale = options.scale
        #if os(macOS)
        guard let image = renderer.nsImage else {
            logger?.warning("Failed to render screenshot for \(demoID)")
            return
        }
        let fileType: NSBitmapImageRep.FileType = options.format == .jpg ? .jpeg : .png
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: fileType, properties: [:]) else {
            logger?.warning("Failed to encode screenshot for \(demoID)")
            return
        }
        let url = options.fileURL(demoID: demoID)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            logger?.info("Screenshot saved to \(url.path)")
            if options.reveal {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        } catch {
            logger?.warning("Failed to write screenshot: \(error.localizedDescription)")
        }
        #endif
    }

    private func demoLabel(for metadata: DemoMetadata) -> some View {
        Label(metadata.name, systemImage: metadata.systemImage)
            .truncationMode(.tail)
            .lineLimit(1)
            .foregroundStyle(viewModel.selection == metadata.id ? Color.primary : (configuration.showColors ? (metadata.color ?? Color.primary) : Color.primary))
            .applyLabelStyle(showIcons: configuration.showIcons)
    }

    // Rows are plain content tagged for List selection rather than NavigationLinks: a link label
    // swallows clicks, so keyword tags nested inside one could never be tapped.
    private func navigationLink(for metadata: DemoMetadata) -> some View {
        HStack {
            VStack(alignment: .leading) {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        demoLabel(for: metadata)
                        if configuration.showKeywordTags {
                            KeywordsView(
                                keywords: metadata.keywords,
                                selectedKeyword: selectedKeyword
                            ) { keyword in
                                toggleKeywordFilter(keyword)
                            }
                        }
                    }
                    demoLabel(for: metadata)
                }
                if configuration.showDescriptions, let description = metadata.description {
                    Text(LocalizedStringKey(description))
                        .lineLimit(nil)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(.rect)

            Spacer()

            if configuration.showPinButton {
                pinButton(for: metadata)
            }
        }
        .tag(metadata.id)
        .accessibilityIdentifier(metadata.id.rawValue)
        .onHover { isHovering in
            #if os(macOS)
            hoveredID = isHovering ? metadata.id : nil
            #endif
        }
        .contextMenu {
            contextMenuContent(for: metadata)
        }
        .help("Name: \(metadata.name)\nID: \(metadata.id.rawValue)\(metadata.description.map { "\nDescription: \($0)" } ?? "")\(metadata.longDescription.map { "\n\($0)" } ?? "")")
    }

    @ViewBuilder
    private func pinButton(for metadata: DemoMetadata) -> some View {
        let pinImageName = viewModel.isPinned(metadata.id) ? "pin.fill" : "pin"
        let pinColor = viewModel.selection == metadata.id ? Color.primary : (viewModel.isPinned(metadata.id) ? Color.accentColor : Color.secondary)

        #if os(macOS)
        Button {
            viewModel.togglePin(for: metadata.id)
        } label: {
            Image(systemName: pinImageName)
                .accessibilityLabel(viewModel.isPinned(metadata.id) ? "Unpin" : "Pin")
                .foregroundStyle(pinColor)
        }
        .buttonStyle(.plain)
        .opacity(hoveredID == metadata.id || viewModel.isPinned(metadata.id) ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: hoveredID)
        .help(viewModel.isPinned(metadata.id) ? "Unpin demo" : "Pin demo")
        #else
        Button {
            viewModel.togglePin(for: metadata.id)
        } label: {
            Image(systemName: pinImageName)
                .accessibilityLabel(viewModel.isPinned(metadata.id) ? "Unpin" : "Pin")
                .foregroundStyle(pinColor)
        }
        .buttonStyle(.plain)
        .help(viewModel.isPinned(metadata.id) ? "Unpin demo" : "Pin demo")
        #endif
    }

    @ViewBuilder
    private func contextMenuContent(for metadata: DemoMetadata) -> some View {
        Button {
            viewModel.togglePin(for: metadata.id)
        } label: {
            Label(
                viewModel.isPinned(metadata.id) ? "Unpin Demo" : "Pin Demo",
                systemImage: viewModel.isPinned(metadata.id) ? "pin.slash" : "pin"
            )
        }

        Divider()

        Button {
            viewModel.toggleHidden(for: metadata.id)
        } label: {
            Label("Hide Demo", systemImage: "eye.slash")
        }

        if !viewModel.hiddenDemoIDs.isEmpty {
            Button {
                viewModel.unhideAll()
            } label: {
                Label("Unhide All Demos (\(viewModel.hiddenDemoIDs.count))", systemImage: "eye")
            }
        }
    }
}

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

    @ViewBuilder
    func applyLabelStyle(showIcons: Bool) -> some View {
        if showIcons {
            self.labelStyle(.titleAndIcon)
        } else {
            self.labelStyle(.titleOnly)
        }
    }
}
