import Observation
import SwiftUI

@Observable
@MainActor
public final class DemoPickerViewModel {
    public let demos: [any DemoView.Type]
    public var selection: DemoMetadata.ID?

    @ObservationIgnored
    @AppStorage("demoview")
    private var storedSelection: String = "" {
        didSet {
            guard storedSelection != selection?.rawValue else { return }
            loadStoredSelection()
        }
    }

    public init(demos: [any DemoView.Type]) {
        self.demos = demos
        loadInitialSelection()
    }

    private func loadInitialSelection() {
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
        let elements = demos.map { $0.metadata }

        guard !storedSelection.isEmpty else {
            let firstID = elements.first?.id
            selection = firstID
            return
        }

        let storedID = DemoMetadata.ID(storedSelection)
        if elements.contains(where: { $0.id == storedID }) {
            selection = storedID
        }
        else {
            selection = elements.first?.id
        }
    }

    func selectionDidChange() {
        storedSelection = selection?.rawValue ?? ""
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
        let id = DemoMetadata.ID(demoID)

        guard demos.contains(where: { $0.metadata.id == id }) else {
            logger?.warning("Demo with ID '\(demoID)' not found in \(self.demos.count) available demos")
            return
        }
        selection = id
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
