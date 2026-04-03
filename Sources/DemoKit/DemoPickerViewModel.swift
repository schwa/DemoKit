import Observation
import SwiftUI

@Observable
@MainActor
public final class DemoPickerViewModel {
    public let demos: [any DemoView.Type]
    public var selection: DemoMetadata.ID?
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

    func handleURL(_ url: URL, urlScheme: String?) {
        guard let urlScheme else {
            return
        }

        guard url.scheme == urlScheme else {
            return
        }

        let demoID = extractDemoID(from: url)

        guard let demoID else {
            logger?.warning("Could not extract demo ID from URL: \(url.absoluteString)")
            return
        }

        logger?.info("Extracted demo ID: \(demoID)")

        let allMetadata = demos.map { $0.metadata }

        // Try exact ID match, then kebab-cased, then case-insensitive ID, then case-insensitive name
        let matched: DemoMetadata.ID? =
            allMetadata.first(where: { $0.id.rawValue == demoID })?.id
            ?? allMetadata.first(where: { $0.id.rawValue == DemoMetadata.kebabCase(demoID) })?.id
            ?? allMetadata.first(where: { $0.id.rawValue.lowercased() == demoID.lowercased() })?.id
            ?? allMetadata.first(where: { $0.name.lowercased().replacingOccurrences(of: " ", with: "") == demoID.lowercased().replacingOccurrences(of: " ", with: "") })?.id

        guard let matched else {
            logger?.warning("Demo with ID '\(demoID)' not found in \(self.demos.count) available demos")
            return
        }
        logger?.info("URL navigated to demo: \(matched.rawValue)")
        selection = matched
    }

    private func extractDemoID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        if let openDemoValue = components.queryItems?.first(where: { $0.name == "openDemo" })?.value,
           !openDemoValue.isEmpty {
            return openDemoValue
        }

        if let host = components.host, !host.isEmpty {
            return host
        }

        return nil
    }
}
