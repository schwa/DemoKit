import SwiftUI
import DemoKit

@main
struct DemoApp: App {
    var body: some Scene {
        DemoPickerScene(demos: [
            DemoView1.self,
            DemoView2.self,
            DemoView3.self,
        ])
        .handleDemoURLScheme("x-demo")
    }
}
