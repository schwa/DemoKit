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

struct KeywordsView: View {
    let keywords: [String]


    var body: some View {

        DiscardingHStack {
            ForEach(keywords, id: \.self) { keyword in
                Text(keyword)
                    .fixedSize()
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding([.leading, .trailing], 4)
                    .padding([.top, .bottom], 2)
                    .background(Color.green, in: Capsule())
            }

        }

    }
}

struct DiscardingHStack: Layout {

    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Determine the maximum width we can use; if unspecified, lay out all subviews.
        let maxWidth = proposal.width ?? .infinity

        var usedWidth: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            // Propose remaining width for each subview, unlimited height.
            let remainingWidth = max(0, maxWidth.isFinite ? maxWidth - usedWidth : .infinity)
            let subProposal = ProposedViewSize(width: remainingWidth.isFinite ? remainingWidth : nil, height: proposal.height)
            let size = subview.sizeThatFits(subProposal)

            // If placing this subview would exceed the available width, discard the rest.
            if maxWidth.isFinite, usedWidth + size.width > maxWidth {
                break
            }

            usedWidth += size.width
            maxHeight = max(maxHeight, size.height)
        }

        // Respect proposed height if given, otherwise use measured height.
        let height = proposal.height ?? maxHeight
        // If width is unspecified, report usedWidth; if specified, cap at that.
        let width = proposal.width ?? usedWidth
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        let y = bounds.minY
        let maxX = bounds.maxX

        for subview in subviews {
            let remainingWidth = max(0, maxX - x)
            // If no remaining width, stop placing further subviews.
            if remainingWidth <= 0 { break }

            let subProposal = ProposedViewSize(width: remainingWidth, height: bounds.height)
            let size = subview.sizeThatFits(subProposal)

            // If this subview doesn't fit, stop placing more (discard remainder).
            if x + size.width > maxX {
                break
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: bounds.height)
            )
            x += size.width
        }
    }
}

struct SampleDemoView1: DemoView {
    static var metadata = DemoMetadata(
        name: "Sample Demo 1",
        description: "This is a sample demo view 1",
        keywords: ["sample", "demo"]
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
        keywords: ["sample", "demo"]
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
        keywords: ["sample", "demo"],
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
