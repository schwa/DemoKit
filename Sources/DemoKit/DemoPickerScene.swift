import SwiftUI

public struct DemoPickerScene: Scene {
    let demos: [any DemoView.Type]
    @Environment(\.demoURLScheme) private var urlScheme

    public init(demos: [any DemoView.Type]) {
        self.demos = demos
    }

    public var body: some Scene {
        #if os(macOS)
        Window("Demo", id: "demo") {
            DemoPickerView(demos: demos)
                .environment(\.demoURLScheme, urlScheme)
        }
        #else
        WindowGroup("Demos") {
            DemoPickerView(demos: demos)
                .environment(\.demoURLScheme, urlScheme)
        }
        #endif
    }
}
