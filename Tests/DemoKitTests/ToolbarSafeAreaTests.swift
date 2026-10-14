#if os(macOS)
import AppKit
@testable import DemoKit
import SwiftUI
import Testing

@MainActor
private enum LayoutProbe {
    static var topInsets: [String: CGFloat] = [:]
    static var frames: [String: CGRect] = [:]
    static var descriptionOverlayFrame: CGRect?
}

private struct ProbeView: View {
    var name = "demo"

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { record(proxy) }
                .onChange(of: proxy.frame(in: .global)) { record(proxy) }
                .onChange(of: proxy.safeAreaInsets.top) { record(proxy) }
        }
    }

    private func record(_ proxy: GeometryProxy) {
        LayoutProbe.topInsets[name] = proxy.safeAreaInsets.top
        LayoutProbe.frames[name] = proxy.frame(in: .global)
    }
}

private struct PlainProbeDemo: DemoView {
    static let metadata = DemoMetadata(id: .init("plain-probe"), name: "Plain Probe")
    var body: some View { ProbeView() }
}

private struct ConfiguredProbeDemo: DemoView {
    static let metadata = DemoMetadata(
        id: .init("configured-probe"),
        name: "Configured Probe",
        description: "A demo with a configuration panel"
    )
    var body: some View {
        ProbeView()
            .demoConfiguration { ProbeView(name: "inspector") }
    }
}

@MainActor
private func withHostedDemo<T>(
    _ demo: any DemoView.Type,
    showConfiguration: Bool = false,
    showDescription: Bool = false,
    until ready: () -> Bool,
    _ body: (NSWindow) throws -> T
) async throws -> T {
    LayoutProbe.topInsets = [:]
    LayoutProbe.frames = [:]
    LayoutProbe.descriptionOverlayFrame = nil
    let defaults = UserDefaults.standard
    let previous = [
        "showDemoConfiguration": defaults.object(forKey: "showDemoConfiguration"),
        "showDemoDescription": defaults.object(forKey: "showDemoDescription")
    ]
    defaults.set(showConfiguration, forKey: "showDemoConfiguration")
    defaults.set(showDescription, forKey: "showDemoDescription")
    defer {
        for (key, value) in previous {
            defaults.set(value, forKey: key)
        }
    }
    let viewModel = DemoPickerViewModel(demos: [demo])
    viewModel.selection = demo.metadata.id
    let rootView = DemosNavigationSplitView()
        .environment(viewModel)
        .onPreferenceChange(DescriptionOverlayFrameKey.self) { frame in
            MainActor.assumeIsolated { LayoutProbe.descriptionOverlayFrame = frame }
        }
    let controller = NSHostingController(rootView: rootView)
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
        styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )
    window.isReleasedWhenClosed = false
    window.contentViewController = controller
    window.toolbar = NSToolbar(identifier: "probe")
    window.toolbarStyle = .unified
    window.setContentSize(NSSize(width: 900, height: 600))
    window.orderFront(nil)
    defer { window.close() }
    for _ in 0..<50 {
        try await Task.sleep(for: .milliseconds(20))
        if ready() { break }
    }
    // Let animations (e.g. the overlay transition) settle.
    try await Task.sleep(for: .milliseconds(500))
    return try body(window)
}

@MainActor
private func measureTopInset(of demo: any DemoView.Type, probe: String = "demo", showConfiguration: Bool = false) async throws -> CGFloat {
    try await withHostedDemo(demo, showConfiguration: showConfiguration) {
        (LayoutProbe.topInsets[probe] ?? 0) > 0
    } _: { _ in
        try #require(LayoutProbe.topInsets[probe])
    }
}

@Suite(.serialized)
@MainActor
struct ToolbarSafeAreaTests {
    @Test func plainDemoContentIsInsetBelowToolbar() async throws {
        #expect(try await measureTopInset(of: PlainProbeDemo.self) > 0)
    }

    @Test func configuredDemoContentIsInsetBelowToolbar() async throws {
        #expect(try await measureTopInset(of: ConfiguredProbeDemo.self) > 0)
    }

    @Test func configurationInspectorContentIsInsetBelowToolbar() async throws {
        #expect(try await measureTopInset(of: ConfiguredProbeDemo.self, probe: "inspector", showConfiguration: true) > 0)
    }

    @Test func descriptionOverlayStaysLeftOfInspector() async throws {
        let (overlayMaxX, inspectorMinX) = try await withHostedDemo(
            ConfiguredProbeDemo.self,
            showConfiguration: true,
            showDescription: true
        ) {
            LayoutProbe.frames["inspector"] != nil && LayoutProbe.descriptionOverlayFrame != nil
        } _: { _ in
            let overlay = try #require(LayoutProbe.descriptionOverlayFrame)
            let inspector = try #require(LayoutProbe.frames["inspector"])
            return (overlay.maxX, inspector.minX)
        }
        #expect(overlayMaxX <= inspectorMinX)
    }
}
#endif
