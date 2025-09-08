import Observation
import OSLog
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
            logger?.debug("Stored selection changed to: \(self.storedSelection)")
            loadStoredSelection()
        }
    }

    public init(demos: [any DemoView.Type]) {
        self.demos = demos
        logger?.info("Initializing DemoPickerViewModel with \(demos.count) demos")
        loadInitialSelection()
    }

    private func loadInitialSelection() {
        let elements = demos.map { $0.metadata }

        // First check environment variable
        if let envSelection = ProcessInfo.processInfo.environment["DEMOVIEW"],
           !envSelection.isEmpty {
            logger?.info("Found DEMOVIEW environment variable: \(envSelection)")
            let envID = DemoMetadata.ID(envSelection)
            guard elements.contains(where: { $0.id == envID }) else {
                logger?.warning("Demo with ID '\(envSelection)' from environment not found")
                loadStoredSelection()
                return
            }
            logger?.info("Setting selection from environment: \(envSelection)")
            selection = envID
            return
        }

        // Then check stored selection
        loadStoredSelection()
    }

    private func loadStoredSelection() {
        let elements = demos.map { $0.metadata }

        guard !storedSelection.isEmpty else {
            let firstID = elements.first?.id
            logger?.info("No stored selection, using first demo: \(firstID?.rawValue ?? "none")")
            selection = firstID
            return
        }

        let storedID = DemoMetadata.ID(storedSelection)
        if elements.contains(where: { $0.id == storedID }) {
            logger?.info("Restoring selection from storage: \(self.storedSelection)")
            selection = storedID
        }
        else {
            logger?.warning("Stored selection '\(self.storedSelection)' not found, using first demo")
            selection = elements.first?.id
        }
    }

    func selectionDidChange() {
        let newValue = selection?.rawValue ?? ""
        logger?.debug("Selection changed to: \(newValue)")
        storedSelection = newValue
    }
}
