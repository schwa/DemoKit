import DemoKit
import SwiftUI

@main
struct DemoApp: App {
    init() {
        DemoCrashDetector.install()
    }

    var body: some Scene {
        DemoPickerScene(demos: [
            DemoView1.self,
            DemoView2.self,
            DemoView3.self,
            DemoView4.self
        ])
        .handleDemoURL(scheme: "x-demo")
    }
}
