import DemoKit
import SwiftUI

@main
struct DemoApp: App {
    init() {
        DemoCrashDetector.install()
    }

    var body: some Scene {
        DemoPickerScene(demos: [
            StateTestDemoView.self,
            GradientBackgroundDemoView.self,
            MeshGradientDemoView.self,
            NoisePatternDemoView.self,
            CirclesDemoView.self,
            RoundedPolygonDemoView.self,
            PulseDemoView.self,
            SpinnerDemoView.self,
            BounceDemoView.self,
            GridDemoView.self,
            StackDemoView.self,
            TypographyDemoView.self,
            GradientTextDemoView.self,
            SymbolsDemoView.self,
        ])
        .handleDemoURL(scheme: "x-demo")
        .commands {
            DemosCommandMenu()
        }
    }
}
