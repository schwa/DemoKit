import DemoKit
import SwiftUI

@main
struct DemoApp: App {
    init() {
        DemoCrashDetector.install()
    }

    var body: some Scene {
        DemoPickerScene(demos: [
            EmptyDemoView.self,
            LinksDemoView.self,
            StateTestDemoView.self,
            LinkedSlidersDemoView.self,
            FormMirrorDemoView.self,
            CascadingStatesDemoView.self,
            ListEditorDemoView.self,
            TimerDemoView.self,
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
            SymbolsDemoView.self
        ])
        .handleDemoURL(scheme: "x-demo")
        .commands {
            DemosCommandMenu()
        }
    }
}
