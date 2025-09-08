import SwiftUI
import OSLog

public struct DemoPickerView: View {
    @State private var viewModel: DemoPickerViewModel
    @Environment(\.demoURLScheme) private var urlScheme

    public init(demos: [any DemoView.Type]) {
        self._viewModel = State(initialValue: DemoPickerViewModel(demos: demos))
    }

    public var body: some View {
        DemosNavigationSplitView(viewModel: viewModel)
            .onOpenURL { url in
                handleURL(url)
            }
    }
    
    @MainActor
    private func handleURL(_ url: URL) {
        guard let urlScheme = urlScheme else {
            logger?.debug("No URL scheme configured, ignoring URL: \(url.absoluteString)")
            return
        }
        
        guard url.scheme == urlScheme else {
            logger?.debug("URL scheme '\(url.scheme ?? "nil")' doesn't match configured scheme '\(urlScheme)'")
            return
        }

        logger?.info("Handling URL: \(url.absoluteString)")

        // Extract demo ID from URL
        let demoID = extractDemoID(from: url)
        
        guard let demoID = demoID else {
            logger?.warning("Could not extract demo ID from URL: \(url.absoluteString)")
            return
        }
        
        logger?.info("Extracted demo ID: \(demoID)")
        let id = DemoMetadata.ID(demoID)
        
        // Check if demo exists
        guard viewModel.demos.contains(where: { $0.metadata.id == id }) else {
            logger?.warning("Demo with ID '\(demoID)' not found in \(viewModel.demos.count) available demos")
            return
        }
        
        // Set the selection
        logger?.info("Setting selection to: \(id.rawValue)")
        viewModel.selection = id
    }
    
    private func extractDemoID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        // Check for query parameter first
        if let openDemoValue = components.queryItems?.first(where: { $0.name == "openDemo" })?.value,
           !openDemoValue.isEmpty {
            return openDemoValue
        }
        
        // Fall back to host as demo ID
        if let host = components.host, !host.isEmpty {
            return host
        }
        
        return nil
    }
}
