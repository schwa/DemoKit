import SwiftUI

public struct DemoMetadata: Identifiable, Sendable {
    public var id: ID
    public var name: String
    public var systemImage: String
    public var description: String?
    public var group: String?
    public var keywords: [String]
    public var color: Color?
    public var isEnabled: Bool
    public var variants: [DemoMetadata] = []

    public struct ID: Hashable, Sendable {
        public var rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public init(id: ID? = nil, name: String, systemImage: String = "puzzlepiece", description: String? = nil, group: String? = nil, keywords: [String] = [], color: Color? = nil, isEnabled: Bool = true, variants: [DemoMetadata] = []) {
        self.id = id ?? ID(name)
        self.name = name
        self.systemImage = systemImage
        self.description = description
        self.group = group
        self.keywords = keywords
        self.color = color
        self.isEnabled = isEnabled
        self.variants = variants
    }
}

//let defaultName = "\(type(of: Self.self))"
//    .replacingOccurrences(of: ".Type", with: "")
//    .replacingOccurrences(of: "DemoView", with: "")


public protocol DemoView: View {
    static var metadata: DemoMetadata { get }

    @MainActor
    init()
}

//protocol DemoScene: Scene {
//    static var metadata: DemoMetadata { get }
//
//    @MainActor
//    init()
//}

public struct DemoPickerView: View {
    let demos: [any DemoView.Type]

    public init(demos: [any DemoView.Type]) {
        self.demos = demos
    }

    public var body: some View {
        DemosNavigationSplitView(demos: demos)
    }
}

struct DemosNavigationSplitView: View {
    private let demos: [any DemoView.Type]

    @State
    private var selection: DemoMetadata.ID?

    init(demos: [any DemoView.Type]) {
        self.demos = demos
    }

    var body: some View {
        let elements = demos.map { (type: $0, metadata: $0.metadata) }
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(elements, id: \.metadata.id) { type, metadata in
                    navigationLink(for: metadata)
                }
            }
        } detail: {
            if let id = selection, let element = elements.first(where: { $0.metadata.id == id }) {
                AnyView(element.type.init()).id(id)
            }
        }
        .onAppear {
            if selection == nil {
                selection = elements.first?.metadata.id
            }
        }
    }

    func navigationLink(for metadata: DemoMetadata) -> some View {
        NavigationLink(value: metadata.id) {
            VStack(alignment: .leading) {
                HStack {
                    Label(metadata.name, systemImage: metadata.systemImage)
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .foregroundStyle(metadata.color ?? Color.primary)
                        .labelStyle(.titleAndIcon)
                    KeywordsView(keywords: metadata.keywords)
                }
                if let description = metadata.description {
                    Text(description)
                        .lineLimit(nil)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct TagView: View {
    var text: String

    var body: some View {
        Text(text)
            .fixedSize()
            .font(.caption)
            .foregroundStyle(.white)
            .padding([.leading, .trailing], 4)
            .padding([.top, .bottom], 2)
            .background(Color.accentColor, in: Capsule())

    }
}

struct KeywordsView: View {
    let keywords: [String]

    var body: some View {
        OverflowingHStack {
            ForEach(keywords, id: \.self) { keyword in
                TagView(text: keyword)
            }

        }

    }
}

struct OverflowingHStack <Overflow, Content>: View where Overflow: View, Content: View {
    let spacing: CGFloat

    let overflow: Overflow
    let content: Content

    init(spacing: CGFloat = 8, overflow: Overflow, content: () -> Content) {
        self.spacing = spacing
        self.overflow = overflow
        self.content = content()
    }

    var body: some View {
        Group(subviews: content) { subviews in
            ViewThatFits(in: .horizontal) {
                ForEach(subviews.indices.reversed(), id: \.self) { endIndex in
                    HStack(spacing: spacing) {
                        let subset = subviews[...endIndex]
                        subset
                        if subset.count < subviews.count {
                            overflow
                        }
                    }
                }
            }
        }
    }
}

extension OverflowingHStack where Overflow == Text {
    init(spacing: CGFloat = 8, content: () -> Content) {
        self.init(spacing: spacing, overflow: Text("…"), content: content)
    }
}


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
