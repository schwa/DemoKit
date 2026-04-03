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
            .border(Color.red)
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
            .border(Color.red)
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
        .border(Color.red)
    }
}

struct DemoView4: DemoView {
    static var metadata = DemoMetadata(type: Self.self)
    init() {}
    var body: some View {
        Text("Demo View 4")
            .border(Color.red)
    }
}

struct StateTestDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        description: "Tests that configuration panel updates when state changes",
        group: "Group B",
        keywords: ["state", "bug"]
    )

    @State private var counter = 0
    @State private var color: Color = .blue

    init() {}

    var body: some View {
        VStack(spacing: 20) {
            Text("Counter: \(counter)")
                .font(.largeTitle)
                .foregroundStyle(color)
            Button("Increment from main view") {
                counter += 1
            }
        }
        .demoConfiguration {
            VStack {
                Text("Counter is: \(counter)")
                    .font(.headline)
                Stepper("Counter: \(counter)", value: $counter)
                ColorPicker("Color", selection: $color)
            }
        }
    }
}
