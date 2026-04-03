import SwiftUI

/// Configuration for DemoKit's visual appearance, propagated via SwiftUI environment.
public struct DemoKitConfiguration: Sendable {
    /// Whether to show keyword tags in the sidebar.
    public var showKeywordTags: Bool

    /// Whether to show description text below demo names in the sidebar.
    public var showDescriptions: Bool

    /// Whether to show the demo icon in the sidebar.
    public var showIcons: Bool

    /// Whether to show the pin button in the sidebar.
    public var showPinButton: Bool

    /// Whether to use demo-specified colors for sidebar labels.
    public var showColors: Bool

    public init(
        showKeywordTags: Bool = true,
        showDescriptions: Bool = true,
        showIcons: Bool = true,
        showPinButton: Bool = true,
        showColors: Bool = true
    ) {
        self.showKeywordTags = showKeywordTags
        self.showDescriptions = showDescriptions
        self.showIcons = showIcons
        self.showPinButton = showPinButton
        self.showColors = showColors
    }
}

extension EnvironmentValues {
    @Entry public var demoKitConfiguration: DemoKitConfiguration = DemoKitConfiguration()
}

public extension View {
    func demoKitConfiguration(_ configuration: DemoKitConfiguration) -> some View {
        self.environment(\.demoKitConfiguration, configuration)
    }
}

public extension Scene {
    func demoKitConfiguration(_ configuration: DemoKitConfiguration) -> some Scene {
        self.environment(\.demoKitConfiguration, configuration)
    }
}
