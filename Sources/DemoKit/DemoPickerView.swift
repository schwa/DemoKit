import SwiftUI

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
        guard let urlScheme = urlScheme,
              url.scheme == urlScheme else { return }

        logger?.info("Handling URL: \(url.absoluteString)")

        var demoID: String?
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            // Check for query parameter
            if let openDemoValue = components.queryItems?.first(where: { $0.name == "openDemo" })?.value {
                demoID = openDemoValue
            } else if let host = components.host, !host.isEmpty {
                // Use host as demo ID (e.g., scheme://demoID)
                demoID = host
            }
        }

        

        // If we have a demo ID, try to select it
        if let demoID = demoID {
            logger?.info("DemoID: \(demoID)")
            let id = DemoMetadata.ID(demoID)
            
            // Defer the selection change to ensure view is ready
            Task { @MainActor in
                if viewModel.demos.contains(where: { $0.metadata.id == id }) {
                    logger?.info("Setting selection to: \(id.rawValue)")
                    viewModel.selection = id
                    logger?.info("Selection is now: \(viewModel.selection?.rawValue ?? "nil")")
                } else {
                    logger?.warning("Demo with ID \(demoID) not found in demos")
                }
            }
        }
    }
}
