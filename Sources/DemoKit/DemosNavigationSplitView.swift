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

    private var visibleElements: [(type: any DemoView.Type, metadata: DemoMetadata)] {
        viewModel.demos
            .map { (type: $0, metadata: $0.metadata) }
            .filter { !viewModel.isHidden($0.metadata.id) }
    }

    private var filteredElements: [(type: any DemoView.Type, metadata: DemoMetadata)] {
        guard !searchText.isEmpty else { return visibleElements }

        let searchLower = searchText.lowercased()
        return visibleElements.filter { element in
            let metadata = element.metadata
            return metadata.name.lowercased().contains(searchLower) ||
                   (metadata.description?.lowercased().contains(searchLower) ?? false) ||
                   (metadata.longDescription?.lowercased().contains(searchLower) ?? false) ||
                   metadata.keywords.contains { $0.lowercased().contains(searchLower) }
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
    private var configurationStore = DemoConfigurationStore()

    @State
    private var hasConfiguration = false

    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    private var effectiveUseInspector: Bool {
        #if os(visionOS)
        return false
        #else
        return configuration.useInspector
        #endif
    }

    var body: some View {
        NavigationSplitView {
            demoList
        } detail: {
            detailView
        }
        .modifier(InspectorAttachment(
            showConfiguration: $showConfiguration,
            useInspector: effectiveUseInspector && hasConfiguration,
            store: configurationStore
        ))
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

    @ViewBuilder
    private var listContent: some View {
        if filteredElements.isEmpty, !searchText.isEmpty {
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
            .environment(configurationStore)
            .onPreferenceChange(HasDemoConfigurationPreferenceKey.self) { value in
                hasConfiguration = value
                if !value {
                    showConfiguration = false
                    configurationStore.content = nil
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
            .onChange(of: viewModel.screenshotRequested) { _, requested in
                guard requested else { return }
                viewModel.screenshotRequested = false
                takeScreenshot(of: demoView, demoID: element.metadata.id.rawValue)
            }
        } else {
            ContentUnavailableView("Select a Demo", systemImage: "sidebar.left", description: Text("Choose a demo from the sidebar"))
        }
    }

    private func takeScreenshot<V: View>(of view: V, demoID: String) {
        let renderer = ImageRenderer(content: view.frame(width: 800, height: 600).background(Color.white))
        renderer.scale = 2.0
        #if os(macOS)
        guard let image = renderer.nsImage else {
            logger?.warning("Failed to render screenshot for \(demoID)")
            return
        }
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            logger?.warning("Failed to encode screenshot for \(demoID)")
            return
        }
        let filename = "DemoKit-\(demoID).png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try pngData.write(to: url)
            logger?.info("Screenshot saved to \(url.path)")
            NSWorkspace.shared.activateFileViewerSelecting([url])
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

    private func navigationLink(for metadata: DemoMetadata) -> some View {
        HStack {
            NavigationLink(value: metadata.id) {
                VStack(alignment: .leading) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            demoLabel(for: metadata)
                            if configuration.showKeywordTags {
                                KeywordsView(keywords: metadata.keywords)
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
            }

            Spacer()

            if configuration.showPinButton {
                pinButton(for: metadata)
            }
        }
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

private struct InspectorAttachment: ViewModifier {
    @Binding var showConfiguration: Bool
    let useInspector: Bool
    let store: DemoConfigurationStore

    func body(content: Content) -> some View {
        if useInspector {
            #if !os(visionOS)
            content
                .inspector(isPresented: $showConfiguration) {
                    Group {
                        if let configContent = store.content {
                            configContent
                        }
                    }
                    .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
                }
            #else
            content
            #endif
        } else {
            content
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
