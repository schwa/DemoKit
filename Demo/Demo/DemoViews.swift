import DemoKit
import SwiftUI

struct DemoView1: DemoView {
    static var metadata = DemoMetadata(
        name: "Demo View 1",
        description: "This is a demo view 1",
        group: "Group A",
        keywords: ["tag 1", "tag 2"]
    )
    init() {}
    var body: some View {
        Text("Demo View 1")
    }
}

struct DemoView2: DemoView {
    static var metadata = DemoMetadata(
        name: "Demo View 2",
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
        name: "Demo View 3",
        description: "This is a demo view 3",
        group: "Group A",
        keywords: ["a very long tab", "another very long tag"]
    )
    init() {}
    var body: some View {
        Text("Demo View 3")
    }
}
