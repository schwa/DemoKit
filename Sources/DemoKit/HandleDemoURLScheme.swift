import SwiftUI

extension EnvironmentValues {
    @Entry var demoURLScheme: String?
}

public extension View {
    func handleDemoURL(scheme: String) -> some View {
        self.environment(\.demoURLScheme, scheme)
    }
}

public extension Scene {
    /// Note: Scene environment does not propagate to View environment in SwiftUI.
    /// Prefer applying `.handleDemoURL(scheme:)` to the root View inside the Scene instead.
    func handleDemoURL(scheme: String) -> some Scene {
        self.environment(\.demoURLScheme, scheme)
    }
}
