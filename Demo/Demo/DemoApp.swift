import DemoKit
import SwiftUI

@main
struct DemoApp: App {
    var body: some Scene {
        DemoPickerScene(demos: [
            DemoView1.self,
            DemoView2.self,
            MyComplexDemoView.self
        ])
        .handleDemoURL(scheme: "x-demo")
    }
}
