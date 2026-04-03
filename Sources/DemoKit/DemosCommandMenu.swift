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

// Retains last non-nil focused viewModel so menus work even when the window isn't key.
@MainActor
enum FocusedViewModelRetainer {
    static var viewModel: DemoPickerViewModel?
}

public struct DemosCommandMenu: Commands {
    @FocusedValue(\.demoPickerViewModel)
    private var focusedViewModel

    private var viewModel: DemoPickerViewModel? {
        if let focusedViewModel {
            FocusedViewModelRetainer.viewModel = focusedViewModel
            return focusedViewModel
        }
        return FocusedViewModelRetainer.viewModel
    }

    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    @AppStorage("showDemoDescription")
    private var showDescription = false

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
                Button(showDescription ? "Hide Description" : "Show Description") {
                    showDescription.toggle()
                }
                .keyboardShortcut("i", modifiers: .command)
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
        let ids = viewModel.visibleIDs()
        let currentIndex = viewModel.selection.flatMap { ids.firstIndex(of: $0) }

        Button("Previous Demo") {
            viewModel.selectPreviousDemo()
        }
        .keyboardShortcut("[", modifiers: .command)
        .disabled(currentIndex == nil || currentIndex == ids.startIndex)

        Button("Next Demo") {
            viewModel.selectNextDemo()
        }
        .keyboardShortcut("]", modifiers: .command)
        .disabled(currentIndex == nil || currentIndex == ids.index(before: ids.endIndex))
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

}
