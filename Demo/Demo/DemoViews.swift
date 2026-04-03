import DemoKit
import SwiftUI

struct StateTestDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        description: "Tests that configuration panel updates when state changes",
        longDescription: "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam.",
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

// MARK: - Shapes

struct CirclesDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "circle.hexagongrid",
        description: "Overlapping circles with blend modes",
        longDescription: "Demonstrates how SwiftUI blend modes interact when layering colored shapes on top of each other.",
        group: "Shapes",
        keywords: ["blend", "circles"],
        color: .purple
    )

    @State private var radius: Double = 60

    init() {}
    var body: some View {
        ZStack {
            Circle()
                .fill(.red)
                .frame(width: radius * 2, height: radius * 2)
                .offset(x: -radius / 2, y: -radius / 2)
            Circle()
                .fill(.green)
                .frame(width: radius * 2, height: radius * 2)
                .offset(x: radius / 2, y: -radius / 2)
            Circle()
                .fill(.blue)
                .frame(width: radius * 2, height: radius * 2)
                .offset(y: radius / 2)
        }
        .blendMode(.screen)
        .demoConfiguration {
            LabeledContent("Radius") {
                Slider(value: $radius, in: 20...150)
            }
        }
    }
}

struct RoundedPolygonDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "pentagon",
        description: "A configurable rounded polygon",
        longDescription: "Experiment with the number of sides, corner radius, and rotation of a polygon shape.",
        group: "Shapes",
        keywords: ["polygon", "geometry"]
    )

    @State private var sides: Double = 5
    @State private var cornerRadius: Double = 10
    @State private var rotation: Double = 0

    init() {}
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.indigo.gradient)
            .frame(width: 200, height: 200)
            .rotationEffect(.degrees(rotation))
            .overlay {
                Text("\(Int(sides)) sides")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            .demoConfiguration {
                LabeledContent("Sides") {
                    Slider(value: $sides, in: 3...12, step: 1)
                }
                LabeledContent("Corner Radius") {
                    Slider(value: $cornerRadius, in: 0...50)
                }
                LabeledContent("Rotation") {
                    Slider(value: $rotation, in: 0...360)
                }
            }
    }
}

// MARK: - Animation

struct PulseDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "waveform.circle",
        description: "A pulsing animation effect",
        longDescription: "Shows a repeating scale and opacity animation on a circle, useful for loading indicators or attention-grabbing UI.",
        group: "Animation",
        keywords: ["pulse", "animation"],
        color: .orange
    )

    @State private var isPulsing = false

    init() {}
    var body: some View {
        Circle()
            .fill(.orange.gradient)
            .frame(width: 100, height: 100)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

struct SpinnerDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "arrow.trianglehead.2.counterclockwise",
        description: "A customizable spinning loader",
        longDescription: "Renders a trimmed circle that rotates continuously. Configure the trim amount and speed.",
        group: "Animation",
        keywords: ["spinner", "loading"]
    )

    @State private var isSpinning = false
    @State private var trim: Double = 0.3
    @State private var lineWidth: Double = 6

    init() {}
    var body: some View {
        Circle()
            .trim(from: 0, to: trim)
            .stroke(.teal, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
            .demoConfiguration {
                LabeledContent("Trim") {
                    Slider(value: $trim, in: 0.1...0.9)
                }
                LabeledContent("Line Width") {
                    Slider(value: $lineWidth, in: 2...20)
                }
            }
    }
}

struct BounceDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "arrow.up.arrow.down",
        description: "A bouncing ball animation",
        longDescription: "A simple ball that bounces up and down with a spring animation. Demonstrates repeating spring physics.",
        group: "Animation",
        keywords: ["bounce", "spring"]
    )

    @State private var isBouncing = false

    init() {}
    var body: some View {
        Circle()
            .fill(.mint.gradient)
            .frame(width: 50, height: 50)
            .offset(y: isBouncing ? 100 : -100)
            .animation(.interpolatingSpring(stiffness: 200, damping: 5).repeatForever(autoreverses: true), value: isBouncing)
            .onAppear { isBouncing = true }
    }
}

// MARK: - Layout

struct GridDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "square.grid.3x3",
        description: "A color grid layout",
        longDescription: "Displays a grid of colored squares using LazyVGrid. Configure the number of columns.",
        group: "Layout",
        keywords: ["grid", "colors"],
        color: .cyan
    )

    @State private var columns: Double = 4
    private let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown]

    init() {}
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: Int(columns)), spacing: 8) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors[index].gradient)
                    .frame(height: 60)
            }
        }
        .padding()
        .frame(maxWidth: 400)
        .demoConfiguration {
            LabeledContent("Columns") {
                Slider(value: $columns, in: 2...6, step: 1)
            }
        }
    }
}

struct StackDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "square.3.layers.3d",
        description: "Stacked cards with depth effect",
        longDescription: "Cards stacked with offset and rotation to create a fanned-out deck effect. Adjust the spread and angle.",
        group: "Layout",
        keywords: ["stack", "cards"]
    )

    @State private var spread: Double = 15
    @State private var angle: Double = 5

    init() {}
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hue: Double(index) / 5.0, saturation: 0.7, brightness: 0.9).gradient)
                    .frame(width: 150, height: 200)
                    .offset(x: Double(index - 2) * spread)
                    .rotationEffect(.degrees(Double(index - 2) * angle))
            }
        }
        .demoConfiguration {
            LabeledContent("Spread") {
                Slider(value: $spread, in: 0...40)
            }
            LabeledContent("Angle") {
                Slider(value: $angle, in: 0...15)
            }
        }
    }
}

// MARK: - Text

struct TypographyDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "textformat",
        description: "Typography scale showcase",
        longDescription: "Displays all the built-in SwiftUI font styles from large title down to caption, useful as a quick reference.",
        group: "Text",
        keywords: ["fonts", "typography"]
    )

    init() {}
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Large Title").font(.largeTitle)
            Text("Title").font(.title)
            Text("Title 2").font(.title2)
            Text("Title 3").font(.title3)
            Text("Headline").font(.headline)
            Text("Subheadline").font(.subheadline)
            Text("Body").font(.body)
            Text("Callout").font(.callout)
            Text("Footnote").font(.footnote)
            Text("Caption").font(.caption)
            Text("Caption 2").font(.caption2)
        }
        .padding()
    }
}

struct GradientTextDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "paintbrush",
        description: "Text with animated gradient fill",
        longDescription: "A large text label rendered with a moving linear gradient, creating a shimmering rainbow effect.",
        group: "Text",
        keywords: ["gradient", "rainbow"],
        color: .pink
    )

    @State private var phase: CGFloat = 0

    init() {}
    var body: some View {
        Text("Hello, World!")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct SymbolsDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "star.square.on.square",
        description: "SF Symbols browser",
        longDescription: "A small sampling of SF Symbols rendered in a grid. Shows variable rendering and symbol effects.",
        group: "Text",
        keywords: ["symbols", "icons"]
    )

    private let symbols = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill",
                           "drop.fill", "cloud.fill", "moon.fill", "sun.max.fill", "snowflake",
                           "wind", "sparkles", "camera.fill", "mic.fill", "bell.fill",
                           "tag.fill", "flag.fill", "pin.fill", "mappin", "globe"]

    init() {}
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 5), spacing: 16) {
            ForEach(symbols, id: \.self) { name in
                Image(systemName: name)
                    .font(.title)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
            }
        }
        .padding()
    }
}
