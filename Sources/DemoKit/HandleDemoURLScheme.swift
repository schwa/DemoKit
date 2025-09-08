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
    func handleDemoURL(scheme: String) -> some Scene {
        self.environment(\.demoURLScheme, scheme)
    }
}
