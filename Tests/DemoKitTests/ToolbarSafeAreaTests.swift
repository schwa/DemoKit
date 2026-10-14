#if os(macOS)
import AppKit
@testable import DemoKit
import SwiftUI
import Testing

@MainActor
private enum SafeAreaProbe {
    static var topInsets: [String: CGFloat] = [:]
}

private struct ProbeView: View {
    var name = "demo"

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { SafeAreaProbe.topInsets[name] = proxy.safeAreaInsets.top }
                .onChange(of: proxy.safeAreaInsets.top) { _, value in SafeAreaProbe.topInsets[name] = value }
        }
    }
}

private struct PlainProbeDemo: DemoView {
    static let metadata = DemoMetadata(id: .init("plain-probe"), name: "Plain Probe")
    var body: some View { ProbeView() }
}

private struct ConfiguredProbeDemo: DemoView {
    static let metadata = DemoMetadata(id: .init("configured-probe"), name: "Configured Probe")
    var body: some View {
        ProbeView()
            .demoConfiguration { ProbeView(name: "inspector") }
    }
}

@MainActor
private func measureTopInset(of demo: any DemoView.Type, probe: String = "demo", showConfiguration: Bool = false) async throws -> CGFloat {
    SafeAreaProbe.topInsets = [:]
    let defaults = UserDefaults.standard
    let previousShowConfiguration = defaults.object(forKey: "showDemoConfiguration")
    defaults.set(showConfiguration, forKey: "showDemoConfiguration")
    defer { defaults.set(previousShowConfiguration, forKey: "showDemoConfiguration") }
    let viewModel = DemoPickerViewModel(demos: [demo])
    viewModel.selection = demo.metadata.id
    let controller = NSHostingController(rootView: DemosNavigationSplitView().environment(viewModel))
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
        if let inset = SafeAreaProbe.topInsets[probe], inset > 0 { break }
    }
    return try #require(SafeAreaProbe.topInsets[probe])
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
}
#endif
