import SwiftUI

extension EnvironmentValues {
    @Entry var demoURLScheme: String?
}

public extension View {
    func handleDemoURLScheme(_ scheme: String) -> some View {
        self.environment(\.demoURLScheme, scheme)
    }
}

public extension Scene {
    func handleDemoURLScheme(_ scheme: String) -> some Scene {
        self.environment(\.demoURLScheme, scheme)
    }
}
