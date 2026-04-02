import DemoKit
import SwiftUI

struct DemoView1: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        description: "This is a demo view 1",
        group: "Group A",
        keywords: ["tag 1", "tag 2"],
        color: .green
    )

    @State private var scale: Double = 1.0
    @State private var rotation: Double = 0.0

    init() {}
    var body: some View {
        Text("Demo View 1")
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .demoConfiguration {
                LabeledContent("Scale") {
                    Slider(value: $scale, in: 0.5...3.0)
                }
                LabeledContent("Rotation") {
                    Slider(value: $rotation, in: 0...360)
                }
            }
    }
}

struct DemoView2: DemoView {
    static var metadata = DemoMetadata(
        name: "Demo View 2",
        systemImage: "star",
        description: "This is a demo view 2",
        group: "Group A"
    )
    init() {}
    var body: some View {
        Text("Demo View 2")
    }
}

struct DemoView3: DemoView {
    static var metadata = DemoMetadata(
        id: .init("custom-id"),
        description: "This demonstrates ID to name conversion",
        group: "Group A",
        keywords: ["a very long tab", "another very long tag"]
    )
    init() {}
    var body: some View {
        Text("Demo View 3")
    }
}

struct DemoView4: DemoView {
    static var metadata = DemoMetadata(type: Self.self)
    init() {}
    var body: some View {
        Text("Demo View 4")
    }
}
