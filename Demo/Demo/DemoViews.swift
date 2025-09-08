import DemoKit
import SwiftUI

struct DemoView1: DemoView {
    static var metadata = DemoMetadata(
        description: "This is a demo view 1",
        group: "Group A",
        keywords: ["tag 1", "tag 2"],
        color: .green
    )
    init() {}
    var body: some View {
        Text("Demo View 1")
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

struct MyComplexDemoView: DemoView {
    static var metadata = DemoMetadata(
        id: .init("custom-id"),
        description: "This demonstrates ID to name conversion",
        group: "Group A",
        keywords: ["a very long tab", "another very long tag"]
    )
    init() {}
    var body: some View {
        Text("My Complex Demo View")
    }
}
