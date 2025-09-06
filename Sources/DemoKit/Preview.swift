import SwiftUI

struct SampleDemoView1: DemoView {
    static var metadata = DemoMetadata(
        name: "Sample Demo 1",
        description: "This is a sample demo view 1",
        keywords: ["tag 1", "tag 2"]
    )
    init() {}
    var body: some View {
        Text("Sample Demo View 1")
    }
}
struct SampleDemoView2: DemoView {
    static var metadata = DemoMetadata(
        name: "Sample Demo 2",
        description: "This is a sample demo view 2",
        keywords: ["long tag 1", "long tag 2"]
    )
    init() {}
    var body: some View {
        Text("Sample Demo View 2")
    }
}
struct SampleDemoView3: DemoView {
    static var metadata = DemoMetadata(
        name: "Sample Demo 3",
        systemImage: "gear",
        description: "This is a sample demo view 3",
        color: .blue
    )
    init() {}
    var body: some View {
        Text("Sample Demo View 3")
    }
}

#Preview {
    DemoPickerView(demos: [SampleDemoView1.self, SampleDemoView2.self, SampleDemoView3.self])
}
