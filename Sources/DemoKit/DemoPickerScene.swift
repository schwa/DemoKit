import SwiftUI

public struct DemoPickerScene: Scene {
    let demos: [any DemoView.Type]

    public init(demos: [any DemoView.Type]) {
        self.demos = demos
    }

    public var body: some Scene {
        #if os(macOS)
        Window("Demo", id: "demo") {
            DemoPickerView(demos: demos)
        }
        #else
        WindowGroup("Demos") {
            DemoPickerView(demos: demos)
        }
        #endif
    }
}