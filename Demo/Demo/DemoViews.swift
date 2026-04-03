import DemoKit
import SwiftUI

struct StateTestDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        description: "Tests that configuration panel updates when state changes",
        longDescription: "Verifies that `@State` changes in the **main view** propagate to the `.demoConfiguration` panel and vice versa. If the counter gets out of sync, there's an *identity bug*.",
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
            .accessibilityIdentifier("increment-button")
        }
        .demoConfiguration {
            Form {
                Text("Counter is: \(counter)")
                    .font(.headline)
                Stepper("Counter: \(counter)", value: $counter)
                    .accessibilityLabel("Counter")
                    .accessibilityIdentifier("counter")
                ColorPicker("Color", selection: $color)
            }
        }
    }
}

// MARK: - Edge Cases

struct EmptyDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "rectangle.dashed",
        description: "A completely empty demo",
        longDescription: "Contains **no views at all**. Tests that DemoKit handles an `EmptyView` body gracefully without layout issues.",
        group: "Edge Cases"
    )

    init() {}
    var body: some View {
        EmptyView()
    }
}

struct LinksDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "link",
        description: "Description with a [clickable link](https://developer.apple.com)",
        longDescription: "Tests that **Markdown links** work in both the sidebar and the description overlay. See the [Apple HIG](https://developer.apple.com/design/human-interface-guidelines) and [SwiftUI docs](https://developer.apple.com/documentation/swiftui) for reference.",
        group: "Edge Cases",
        keywords: ["links", "markdown"]
    )

    init() {}
    var body: some View {
        Text("Check the sidebar description and the info overlay for clickable links.")
            .font(.title3)
    }
}

// MARK: - State & Configuration Tests

struct LinkedSlidersDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "slider.horizontal.3",
        description: "Sliders that drive each other and text fields",
        longDescription: "Three `Slider` controls drive **RGB** values that update a color swatch and a `#hex` label in real time. The config panel shows the *numeric value* of each channel alongside its slider.",
        group: "State Tests",
        keywords: ["slider", "binding", "identity"]
    )

    @State private var red: Double = 0.5
    @State private var green: Double = 0.3
    @State private var blue: Double = 0.8

    init() {}
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: red, green: green, blue: blue))
            .frame(width: 200, height: 200)
            .overlay {
                Text(String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255)))
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .demoConfiguration {
                Form {
                    LabeledContent("Red: \(String(format: "%.0f", red * 255))") {
                        Slider(value: $red, in: 0...1)
                            .accessibilityLabel("Red")
                            .accessibilityIdentifier("red")
                    }
                    LabeledContent("Green: \(String(format: "%.0f", green * 255))") {
                        Slider(value: $green, in: 0...1)
                            .accessibilityLabel("Green")
                            .accessibilityIdentifier("green")
                    }
                    LabeledContent("Blue: \(String(format: "%.0f", blue * 255))") {
                        Slider(value: $blue, in: 0...1)
                            .accessibilityLabel("Blue")
                            .accessibilityIdentifier("blue")
                    }
                    Text("Total brightness: \(String(format: "%.0f%%", (red + green + blue) / 3.0 * 100))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
    }
}

struct FormMirrorDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "rectangle.portrait.on.rectangle.portrait",
        description: "Configuration panel mirrors the main view in real time",
        longDescription: "A `TextField`, `Slider`, `Toggle`, and `ColorPicker` in the config panel all drive the **same** `@State` as the main view. Exercises *two-way binding* across the `PreferenceKey` boundary.",
        group: "State Tests",
        keywords: ["form", "mirror", "identity", "binding"]
    )

    @State private var name: String = "Hello"
    @State private var fontSize: Double = 24
    @State private var isBold: Bool = true
    @State private var isItalic: Bool = false
    @State private var color: Color = .blue

    init() {}
    var body: some View {
        VStack(spacing: 16) {
            Text(name)
                .font(.system(size: fontSize, weight: isBold ? .bold : .regular))
                .italic(isItalic)
                .foregroundStyle(color)
            Text("Size: \(String(format: "%.0fpt", fontSize)) • \(isBold ? "Bold" : "Regular") • \(isItalic ? "Italic" : "Upright")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .demoConfiguration {
            Form {
                TextField("Text", text: $name)
                LabeledContent("Font Size: \(String(format: "%.0f", fontSize))pt") {
                    Slider(value: $fontSize, in: 10...72)
                        .accessibilityLabel("Font Size")
                        .accessibilityIdentifier("font-size")
                }
                Toggle("Bold", isOn: $isBold)
                Toggle("Italic", isOn: $isItalic)
                ColorPicker("Color", selection: $color)
            }
        }
    }
}

struct CascadingStatesDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "arrow.triangle.branch",
        description: "State changes cascade through derived values",
        longDescription: "A `baseValue` and `multiplier` drive **computed properties** (`computed`, `percentage`, `clamped`) shown in both views. Uses `Stepper` *and* `Slider` bound to the same `@State`.",
        group: "State Tests",
        keywords: ["cascade", "derived", "computed"]
    )

    @State private var baseValue: Double = 50
    @State private var multiplier: Double = 2

    private var computed: Double { baseValue * multiplier }
    private var percentage: Double { baseValue / 100.0 }
    private var clamped: Double { min(max(computed, 0), 200) }

    init() {}
    var body: some View {
        VStack(spacing: 12) {
            Text("Base: \(String(format: "%.1f", baseValue))")
                .font(.title)
            Text("× \(String(format: "%.1f", multiplier)) = \(String(format: "%.1f", computed))")
                .font(.title2)
            ProgressView(value: percentage)
                .frame(width: 200)
            Text("Clamped: \(String(format: "%.1f", clamped))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .demoConfiguration {
            Form {
                LabeledContent("Base: \(String(format: "%.1f", baseValue))") {
                    Slider(value: $baseValue, in: 0...100)
                        .accessibilityLabel("Base")
                        .accessibilityIdentifier("base")
                }
                LabeledContent("Multiplier: \(String(format: "%.1f", multiplier))") {
                    Slider(value: $multiplier, in: 0.5...5)
                        .accessibilityLabel("Multiplier")
                        .accessibilityIdentifier("multiplier")
                }
                Stepper("Base (stepper): \(String(format: "%.0f", baseValue))", value: $baseValue, in: 0...100, step: 5)
                Text("Computed: \(String(format: "%.1f", computed))")
                    .font(.headline)
                Text("Percentage: \(String(format: "%.0f%%", percentage * 100))")
                Text("Clamped (0–200): \(String(format: "%.1f", clamped))")
            }
        }
    }
}

struct ListEditorDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "list.bullet.rectangle",
        description: "Add and remove items from a list via the config panel",
        longDescription: "Uses `ForEach` with dynamic identity (`id: \\.self`). The config panel can **add**, **remove**, and **shuffle** items. Stresses SwiftUI's *diffing engine* across the preference-key boundary.",
        group: "State Tests",
        keywords: ["list", "dynamic", "identity"]
    )

    @State private var items: [String] = ["Apple", "Banana", "Cherry"]
    @State private var newItem: String = ""

    init() {}
    var body: some View {
        VStack(spacing: 8) {
            if items.isEmpty {
                Text("No items")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.title3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
            }
            Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .demoConfiguration {
            Form {
                HStack {
                    TextField("New item", text: $newItem)
                    Button("Add") {
                        guard !newItem.isEmpty else { return }
                        items.append(newItem)
                        newItem = ""
                    }
                    .disabled(newItem.isEmpty)
                }
                if !items.isEmpty {
                    Button("Remove Last") {
                        items.removeLast()
                    }
                    Button("Shuffle") {
                        items.shuffle()
                    }
                    Button("Clear All", role: .destructive) {
                        items.removeAll()
                    }
                }
                Text("Items: \(items.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TimerDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "timer",
        description: "A live timer with controls in the config panel",
        longDescription: "Updates `@State` every **100ms** via `Timer.scheduledTimer`. Both views show `elapsed` in different formats. Tests that *rapid state mutations* don't cause identity thrashing.",
        group: "State Tests",
        keywords: ["timer", "rapid", "updates"],
        color: .red
    )

    @State private var elapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    init() {}
    var body: some View {
        VStack(spacing: 16) {
            Text(String(format: "%02d:%02d.%d", Int(elapsed) / 60, Int(elapsed) % 60, Int(elapsed * 10) % 10))
                .font(.system(size: 64, weight: .thin, design: .monospaced))
                .foregroundStyle(isRunning ? .primary : .secondary)
            HStack(spacing: 20) {
                Button(isRunning ? "Stop" : "Start") {
                    toggleTimer()
                }
                Button("Reset") {
                    stopTimer()
                    elapsed = 0
                }
                .disabled(elapsed == 0 && !isRunning)
            }
            .buttonStyle(.borderedProminent)
        }
        .demoConfiguration {
            Form {
                Text("Elapsed: \(String(format: "%.1f", elapsed))s")
                    .font(.headline)
                Text("Minutes: \(String(format: "%.2f", elapsed / 60.0))")
                Text("Status: \(isRunning ? "Running" : "Stopped")")
                    .foregroundStyle(isRunning ? .green : .red)
                Button(isRunning ? "Stop" : "Start") {
                    toggleTimer()
                }
                Button("Reset") {
                    stopTimer()
                    elapsed = 0
                }
                Button("+10 seconds") {
                    elapsed += 10
                }
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    elapsed += 0.1
                }
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Backgrounds

struct GradientBackgroundDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "rectangle.inset.filled",
        description: "Full-size view with a configurable gradient background",
        longDescription: "Uses `Color.clear.background(LinearGradient(...)).frame(maxWidth: .infinity, maxHeight: .infinity)` to fill the entire detail area. Exercises the *full-bleed* layout path.",
        group: "Backgrounds",
        keywords: ["gradient", "background", "color"],
        color: .indigo
    )

    @State private var hue: Double = 0.6
    @State private var angle: Double = 0
    @State private var saturation: Double = 0.8

    init() {}
    var body: some View {
        Color.clear
            .background(
                LinearGradient(
                    colors: [
                        Color(hue: hue, saturation: saturation, brightness: 0.9),
                        Color(hue: (hue + 0.3).truncatingRemainder(dividingBy: 1.0), saturation: saturation, brightness: 0.5),
                    ],
                    startPoint: UnitPoint(x: cos(angle * .pi / 180), y: sin(angle * .pi / 180)),
                    endPoint: UnitPoint(x: cos((angle + 180) * .pi / 180), y: sin((angle + 180) * .pi / 180))
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .demoConfiguration {
                Form {
                    LabeledContent("Hue: \(String(format: "%.0f°", hue * 360))") {
                        Slider(value: $hue, in: 0...1)
                            .accessibilityLabel("Hue")
                            .accessibilityIdentifier("hue")
                    }
                    LabeledContent("Saturation: \(String(format: "%.0f%%", saturation * 100))") {
                        Slider(value: $saturation, in: 0...1)
                            .accessibilityLabel("Saturation")
                            .accessibilityIdentifier("saturation")
                    }
                    LabeledContent("Angle: \(String(format: "%.0f°", angle))") {
                        Slider(value: $angle, in: 0...360)
                            .accessibilityLabel("Angle")
                            .accessibilityIdentifier("angle")
                    }
                }
            }
    }
}

struct MeshGradientDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "circle.grid.3x3.fill",
        description: "A large mesh gradient background",
        longDescription: "Uses `MeshGradient` with a draggable **center point**. The 3×3 grid fills the entire view via `.frame(maxWidth: .infinity, maxHeight: .infinity)`.",
        group: "Backgrounds",
        keywords: ["mesh", "gradient", "background"]
    )

    @State private var centerX: Float = 0.5
    @State private var centerY: Float = 0.5

    init() {}
    var body: some View {
        Color.clear
            .background(
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [centerX, centerY], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1],
                ], colors: [
                    .red, .orange, .yellow,
                    .purple, .pink, .mint,
                    .blue, .indigo, .cyan,
                ])
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .demoConfiguration {
                Form {
                    LabeledContent("Center X: \(String(format: "%.2f", centerX))") {
                        Slider(value: $centerX, in: 0...1)
                            .accessibilityLabel("Center X")
                            .accessibilityIdentifier("center-x")
                    }
                    LabeledContent("Center Y: \(String(format: "%.2f", centerY))") {
                        Slider(value: $centerY, in: 0...1)
                            .accessibilityLabel("Center Y")
                            .accessibilityIdentifier("center-y")
                    }
                }
            }
    }
}

struct NoisePatternDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "square.grid.4x3.fill",
        description: "A tiled pattern background with configurable colors",
        longDescription: "Draws a checkerboard using `Canvas` inside `.background { }`. The `Canvas` fills the available space — tile size and colors are driven from `.demoConfiguration`.",
        group: "Backgrounds",
        keywords: ["pattern", "checkerboard", "background"],
        color: .brown
    )

    @State private var tileSize: Double = 40
    @State private var color1: Color = .blue
    @State private var color2: Color = .cyan

    init() {}
    var body: some View {
        Color.clear
            .background {
                Canvas { context, size in
                    let cols = Int(size.width / tileSize) + 1
                    let rows = Int(size.height / tileSize) + 1
                    for row in 0..<rows {
                        for col in 0..<cols {
                            let isEven = (row + col) % 2 == 0
                            let rect = CGRect(x: Double(col) * tileSize, y: Double(row) * tileSize, width: tileSize, height: tileSize)
                            context.fill(Path(rect), with: .color(isEven ? color1 : color2))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .demoConfiguration {
                Form {
                    LabeledContent("Tile Size: \(String(format: "%.0fpx", tileSize))") {
                        Slider(value: $tileSize, in: 10...100)
                            .accessibilityLabel("Tile Size")
                            .accessibilityIdentifier("tile-size")
                    }
                    ColorPicker("Color 1", selection: $color1)
                    ColorPicker("Color 2", selection: $color2)
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
        longDescription: "Three `Circle()` views with `.blendMode(.screen)` overlap to show **additive color mixing**. Adjust the `radius` to change the overlap area.",
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
            Form {
                LabeledContent("Radius") {
                    Slider(value: $radius, in: 20...150)
                        .accessibilityLabel("Radius")
                        .accessibilityIdentifier("radius")
                }
            }
        }
    }
}

struct RoundedPolygonDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "pentagon",
        description: "A configurable rounded polygon",
        longDescription: "A `RoundedRectangle` with configurable `cornerRadius` and `.rotationEffect`. The config panel provides **three sliders** that all update independently.",
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
                Form {
                    LabeledContent("Sides") {
                        Slider(value: $sides, in: 3...12, step: 1)
                            .accessibilityLabel("Sides")
                            .accessibilityIdentifier("sides")
                    }
                    LabeledContent("Corner Radius") {
                        Slider(value: $cornerRadius, in: 0...50)
                            .accessibilityLabel("Corner Radius")
                            .accessibilityIdentifier("corner-radius")
                    }
                    LabeledContent("Rotation") {
                        Slider(value: $rotation, in: 0...360)
                            .accessibilityLabel("Rotation")
                            .accessibilityIdentifier("rotation")
                    }
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
        longDescription: "Uses `.animation(.easeInOut.repeatForever(autoreverses: true))` on `scaleEffect` and `opacity`. The animation starts on `.onAppear` — no configuration needed.",
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
        longDescription: "A `Circle().trim(from:to:)` with `.rotationEffect` animated via `.linear.repeatForever`. The config panel adjusts **trim** and **line width** in real time.",
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
                Form {
                    LabeledContent("Trim") {
                        Slider(value: $trim, in: 0.1...0.9)
                            .accessibilityLabel("Trim")
                            .accessibilityIdentifier("trim")
                    }
                    LabeledContent("Line Width") {
                        Slider(value: $lineWidth, in: 2...20)
                            .accessibilityLabel("Line Width")
                            .accessibilityIdentifier("line-width")
                    }
                }
            }
    }
}

struct BounceDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "arrow.up.arrow.down",
        description: "A bouncing ball animation",
        longDescription: "Uses `.interpolatingSpring(stiffness: 200, damping: 5).repeatForever` to bounce a `Circle` between two `offset` values. Pure *spring physics*, no configuration.",
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
        longDescription: "A `LazyVGrid` with `GridItem(.flexible())` columns. Changing the **column count** via the slider rebuilds the grid layout, testing identity stability.",
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
            Form {
                LabeledContent("Columns") {
                    Slider(value: $columns, in: 2...6, step: 1)
                        .accessibilityLabel("Columns")
                        .accessibilityIdentifier("columns")
                }
            }
        }
    }
}

struct StackDemoView: DemoView {
    static var metadata = DemoMetadata(
        type: Self.self,
        systemImage: "square.3.layers.3d",
        description: "Stacked cards with depth effect",
        longDescription: "Five `RoundedRectangle` cards in a `ZStack`, each with computed `offset` and `rotationEffect`. The **spread** and **angle** sliders update all cards simultaneously.",
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
            Form {
                LabeledContent("Spread") {
                    Slider(value: $spread, in: 0...40)
                        .accessibilityLabel("Spread")
                        .accessibilityIdentifier("spread")
                }
                LabeledContent("Angle") {
                    Slider(value: $angle, in: 0...15)
                        .accessibilityLabel("Angle")
                        .accessibilityIdentifier("angle")
                }
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
        longDescription: "Shows every built-in `Font` style from `.largeTitle` to `.caption2`. Useful as a quick **visual reference** for the SwiftUI type scale.",
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
        longDescription: "Applies a `LinearGradient` as `.foregroundStyle` on a `.system(size: 48)` `Text`. The gradient *would* animate with phase offset — currently static rainbow.",
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
        longDescription: "A `LazyVGrid` of 20 `Image(systemName:)` views with `.foregroundStyle(.tint)`. A quick **sampler** of common SF Symbols.",
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
