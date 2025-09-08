import SwiftUI
import DemoKit

struct DemoView1: DemoView {
    static var metadata = DemoMetadata(
        id: .init("Demo-1"),
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
        id: .init("Demo-2"),
        name: "Demo View 2",
        description: "This is a demo view 2",
        group: "Group A",
        keywords: ["tag 1", "tag 2"]
    )
    init() {}
    var body: some View {
        Text("Demo View 2")
    }
}

struct DemoView3: DemoView {
    static var metadata = DemoMetadata(
        id: .init("Demo-3"),
        name: "Demo View 3",
        description: "This is a demo view 3",
        group: "Group A",
        keywords: ["tag 1", "tag 2"]
    )
    init() {}
    var body: some View {
        Text("Demo View 3")
    }
}
