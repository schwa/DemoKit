import SwiftUI

// Key paths on existential types crash the compiler (Swift 6.3), using closures instead.
// MARK: - Focused Value

struct DemoPickerViewModelKey: FocusedValueKey {
    typealias Value = DemoPickerViewModel
}

extension FocusedValues {
    var demoPickerViewModel: DemoPickerViewModel? {
        get { self[DemoPickerViewModelKey.self] }
        set { self[DemoPickerViewModelKey.self] = newValue }
    }
}

// MARK: - Command Menu

public struct DemosCommandMenu: Commands {
    @FocusedValue(\.demoPickerViewModel)
    private var viewModel

    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    public init() {}

    public var body: some Commands {
        CommandMenu("Demos") {
            if let viewModel {
                navigationItems(viewModel: viewModel)
                Divider()
                Button(showConfiguration ? "Hide Configuration" : "Show Configuration") {
                    showConfiguration.toggle()
                }
                .keyboardShortcut("k", modifiers: .command)
                Divider()
                demoListItems(viewModel: viewModel)
            } else {
                Text("No Demos Available")
                    .disabled(true)
            }
        }
    }

    @ViewBuilder
    private func navigationItems(viewModel: DemoPickerViewModel) -> some View {
        Button("Previous Demo") {
            selectAdjacentDemo(viewModel: viewModel, offset: -1)
        }
        .keyboardShortcut("[", modifiers: .command)
        .disabled(previousDemoID(viewModel: viewModel) == nil)

        Button("Next Demo") {
            selectAdjacentDemo(viewModel: viewModel, offset: 1)
        }
        .keyboardShortcut("]", modifiers: .command)
        .disabled(nextDemoID(viewModel: viewModel) == nil)
    }

    @ViewBuilder
    private func demoListItems(viewModel: DemoPickerViewModel) -> some View {
        let visibleDemos = viewModel.demos
            .map { $0.metadata } // swiftlint:disable:this prefer_key_path
            .filter { !viewModel.isHidden($0.id) }

        let grouped = Dictionary(grouping: visibleDemos) { $0.group }
        let ungrouped = grouped[nil] ?? []
        let sortedGroups = grouped.keys.compactMap(\.self).sorted()

        ForEach(ungrouped) { metadata in
            demoButton(metadata: metadata, viewModel: viewModel)
        }

        ForEach(sortedGroups, id: \.self) { group in
            Section(group) {
                ForEach(grouped[group] ?? []) { metadata in
                    demoButton(metadata: metadata, viewModel: viewModel)
                }
            }
        }
    }

    private func demoButton(metadata: DemoMetadata, viewModel: DemoPickerViewModel) -> some View {
        Button {
            viewModel.selection = metadata.id
        } label: {
            HStack {
                Text(metadata.name)
                if viewModel.selection == metadata.id {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    // MARK: - Navigation Helpers

    private func visibleIDs(viewModel: DemoPickerViewModel) -> [DemoMetadata.ID] {
        let allVisible = viewModel.demos
            .map { $0.metadata } // swiftlint:disable:this prefer_key_path
            .filter { !viewModel.isHidden($0.id) }

        let pinned = allVisible.filter { viewModel.isPinned($0.id) }
        let unpinned = allVisible.filter { !viewModel.isPinned($0.id) }
        let ungrouped = unpinned.filter { $0.group == nil }
        let grouped = Dictionary(grouping: unpinned.filter { $0.group != nil }) { $0.group! }
        let sortedGroups = grouped.keys.sorted()

        var result = pinned.map { $0.id } // swiftlint:disable:this prefer_key_path
        result += ungrouped.map { $0.id } // swiftlint:disable:this prefer_key_path
        for group in sortedGroups {
            result += (grouped[group] ?? []).map { $0.id } // swiftlint:disable:this prefer_key_path
        }
        return result
    }

    private func selectAdjacentDemo(viewModel: DemoPickerViewModel, offset: Int) {
        let ids = visibleIDs(viewModel: viewModel)
        guard !ids.isEmpty else {
            return
        }
        guard let current = viewModel.selection, let index = ids.firstIndex(of: current) else {
            viewModel.selection = ids.first
            return
        }
        let newIndex = index.advanced(by: offset)
        guard ids.indices.contains(newIndex) else {
            return
        }
        viewModel.selection = ids[newIndex]
    }

    private func previousDemoID(viewModel: DemoPickerViewModel) -> DemoMetadata.ID? {
        let ids = visibleIDs(viewModel: viewModel)
        guard let current = viewModel.selection, let index = ids.firstIndex(of: current), index > 0 else {
            return nil
        }
        return ids[index - 1]
    }

    private func nextDemoID(viewModel: DemoPickerViewModel) -> DemoMetadata.ID? {
        let ids = visibleIDs(viewModel: viewModel)
        guard let current = viewModel.selection, let index = ids.firstIndex(of: current), index < ids.count - 1 else {
            return nil
        }
        return ids[index + 1]
    }
}
