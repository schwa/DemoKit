import Observation
import SwiftUI

@Observable
@MainActor
public final class DemoPickerViewModel {
    public let demos: [any DemoView.Type]
    public var selection: DemoMetadata.ID?
    public var screenshotRequested = false
    public var pinnedDemoIDs: Set<DemoMetadata.ID> = []
    public var hiddenDemoIDs: Set<DemoMetadata.ID> = []

    @ObservationIgnored
    @AppStorage("demoview")
    private var storedSelection: String = "" {
        didSet {
            guard storedSelection != selection?.rawValue else { return }
            loadStoredSelection()
        }
    }

    @ObservationIgnored
    @AppStorage("pinnedDemos")
    private var storedPinnedDemos: String = "" {
        didSet {
            loadPinnedDemos()
        }
    }

    @ObservationIgnored
    @AppStorage("hiddenDemos")
    private var storedHiddenDemos: String = "" {
        didSet {
            loadHiddenDemos()
        }
    }

    public init(demos: [any DemoView.Type]) {
        self.demos = demos
        loadPinnedDemos()
        loadHiddenDemos()
        loadInitialSelection()
    }

    private func loadInitialSelection() {
        // swiftlint:disable:next prefer_key_path
        let elements = demos.map { $0.metadata }

        if let envSelection = ProcessInfo.processInfo.environment["DEMOVIEW"],
           !envSelection.isEmpty {
            let envID = DemoMetadata.ID(envSelection)
            guard elements.contains(where: { $0.id == envID }) else {
                logger?.warning("Demo with ID '\(envSelection)' from environment not found")
                loadStoredSelection()
                return
            }
            selection = envID
            return
        }

        loadStoredSelection()
    }

    private func loadStoredSelection() {
        // swiftlint:disable:next prefer_key_path
        let elements = demos.map { $0.metadata }

        guard !storedSelection.isEmpty else {
            #if os(iOS)
            selection = nil
            #else
            let firstID = elements.first?.id
            selection = firstID
            #endif
            return
        }

        let storedID = DemoMetadata.ID(storedSelection)
        if elements.contains(where: { $0.id == storedID }) {
            selection = storedID
        }
        else {
            #if os(iOS)
            selection = nil
            #else
            selection = elements.first?.id
            #endif
        }
    }

    func selectionDidChange() {
        storedSelection = selection?.rawValue ?? ""
    }

    func togglePin(for id: DemoMetadata.ID) {
        if pinnedDemoIDs.contains(id) {
            pinnedDemoIDs.remove(id)
        } else {
            pinnedDemoIDs.insert(id)
        }
        savePinnedDemos()
    }

    func isPinned(_ id: DemoMetadata.ID) -> Bool {
        pinnedDemoIDs.contains(id)
    }

    private func loadPinnedDemos() {
        guard !storedPinnedDemos.isEmpty else {
            pinnedDemoIDs = []
            return
        }

        let ids = storedPinnedDemos.split(separator: ",").map { DemoMetadata.ID(String($0)) }
        pinnedDemoIDs = Set(ids)
    }

    private func savePinnedDemos() {
        storedPinnedDemos = pinnedDemoIDs.map(\.rawValue).sorted().joined(separator: ",")
    }

    func toggleHidden(for id: DemoMetadata.ID) {
        if hiddenDemoIDs.contains(id) {
            hiddenDemoIDs.remove(id)
        } else {
            hiddenDemoIDs.insert(id)
            // If we're hiding the selected demo, clear selection
            if selection == id {
                selection = nil
            }
        }
        saveHiddenDemos()
    }

    func isHidden(_ id: DemoMetadata.ID) -> Bool {
        hiddenDemoIDs.contains(id)
    }

    func unhideAll() {
        hiddenDemoIDs.removeAll()
        saveHiddenDemos()
    }

    private func loadHiddenDemos() {
        guard !storedHiddenDemos.isEmpty else {
            hiddenDemoIDs = []
            return
        }

        let ids = storedHiddenDemos.split(separator: ",").map { DemoMetadata.ID(String($0)) }
        hiddenDemoIDs = Set(ids)
    }

    private func saveHiddenDemos() {
        storedHiddenDemos = hiddenDemoIDs.map(\.rawValue).sorted().joined(separator: ",")
    }

    // MARK: - Navigation

    func visibleIDs() -> [DemoMetadata.ID] {
        let allVisible = demos
            .map { $0.metadata }
            .filter { !isHidden($0.id) }

        let pinned = allVisible.filter { isPinned($0.id) }
        let unpinned = allVisible.filter { !isPinned($0.id) }
        let ungrouped = unpinned.filter { $0.group == nil }
        let grouped = Dictionary(grouping: unpinned.filter { $0.group != nil }) { $0.group! }
        let sortedGroups = grouped.keys.sorted()

        var result = pinned.map { $0.id }
        result += ungrouped.map { $0.id }
        for group in sortedGroups {
            result += (grouped[group] ?? []).map { $0.id }
        }
        return result
    }

    func selectNextDemo() {
        selectAdjacentDemo(offset: 1)
    }

    func selectPreviousDemo() {
        selectAdjacentDemo(offset: -1)
    }

    private func selectAdjacentDemo(offset: Int) {
        let ids = visibleIDs()
        guard !ids.isEmpty else { return }
        guard let current = selection, let index = ids.firstIndex(of: current) else {
            selection = ids.first
            return
        }
        let newIndex = index.advanced(by: offset)
        guard ids.indices.contains(newIndex) else { return }
        selection = ids[newIndex]
    }

    func findDemoID(_ demoID: String) -> DemoMetadata.ID? {
        let allMetadata = demos.map { $0.metadata }
        return allMetadata.first(where: { $0.id.rawValue == demoID })?.id
            ?? allMetadata.first(where: { $0.id.rawValue == DemoMetadata.kebabCase(demoID) })?.id
            ?? allMetadata.first(where: { $0.id.rawValue.lowercased() == demoID.lowercased() })?.id
            ?? allMetadata.first(where: { $0.name.lowercased().replacingOccurrences(of: " ", with: "") == demoID.lowercased().replacingOccurrences(of: " ", with: "") })?.id
    }

    // MARK: - URL Handling

    /// URL scheme: `<scheme>://demo/<id>`, `<scheme>://next`, `<scheme>://previous`, `<scheme>://screenshot`, `<scheme>://screenshot/<id>`
    func handleURL(_ url: URL, urlScheme: String?) {
        guard let urlScheme else { return }
        guard url.scheme == urlScheme else { return }

        let host = url.host ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch host {
        case "demo":
            if !path.isEmpty {
                navigateToDemo(path)
            }
        case "next":
            selectNextDemo()
        case "previous", "prev":
            selectPreviousDemo()
        case "screenshot":
            screenshotRequested = true
        default:
            logger?.warning("Unknown URL action: \(host)")
        }
    }

    private func navigateToDemo(_ demoID: String) {
        guard let matched = findDemoID(demoID) else {
            logger?.warning("Demo with ID '\(demoID)' not found in \(self.demos.count) available demos")
            return
        }
        logger?.info("URL navigated to demo: \(matched.rawValue)")
        selection = matched
    }
}
