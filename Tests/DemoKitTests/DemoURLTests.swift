@testable import DemoKit
import SwiftUI
import Testing

private struct GrassSphereDemoView: DemoView {
    static let metadata = DemoMetadata(type: Self.self, name: "Grass Sphere")
    init() {}
    var body: some View { EmptyView() }
}

private struct PulseDemoView: DemoView {
    static let metadata = DemoMetadata(type: Self.self, name: "Pulse")
    init() {}
    var body: some View { EmptyView() }
}

private struct PulsarDemoView: DemoView {
    static let metadata = DemoMetadata(type: Self.self, name: "Pulsar")
    init() {}
    var body: some View { EmptyView() }
}

@MainActor
private func makeViewModel() -> DemoPickerViewModel {
    DemoPickerViewModel(demos: [PulseDemoView.self, GrassSphereDemoView.self])
}

@MainActor
@Test func navigatesToDemoByKebabCaseID() {
    let viewModel = makeViewModel()
    viewModel.selection = PulseDemoView.metadata.id
    viewModel.handleURL(URL(string: "x-demo://demo/grass-sphere")!, urlScheme: "x-demo")
    #expect(viewModel.selection == GrassSphereDemoView.metadata.id)
}

@MainActor
@Test(arguments: [
    "x-demo://demo/Grass%20Sphere",
    "x-demo://demo/GrassSphere",
    "x-demo://demo/grasssphere"
])
func navigatesToDemoByLooselyMatchedID(urlString: String) {
    let viewModel = makeViewModel()
    viewModel.selection = PulseDemoView.metadata.id
    viewModel.handleURL(URL(string: urlString)!, urlScheme: "x-demo")
    #expect(viewModel.selection == GrassSphereDemoView.metadata.id)
}

@MainActor
@Test(arguments: ["x-demo://demo/grass", "x-demo://demo/sphere", "x-demo://demo/Grass"])
func navigatesToDemoByUniquePartialID(urlString: String) {
    let viewModel = makeViewModel()
    viewModel.selection = PulseDemoView.metadata.id
    viewModel.handleURL(URL(string: urlString)!, urlScheme: "x-demo")
    #expect(viewModel.selection == GrassSphereDemoView.metadata.id)
}

@MainActor
@Test func ignoresAmbiguousPartialID() {
    let viewModel = DemoPickerViewModel(demos: [PulseDemoView.self, PulsarDemoView.self])
    viewModel.selection = PulseDemoView.metadata.id
    viewModel.handleURL(URL(string: "x-demo://demo/puls")!, urlScheme: "x-demo")
    #expect(viewModel.selection == PulseDemoView.metadata.id)
}

@MainActor
@Test func nextAndPreviousMoveSelection() {
    let viewModel = makeViewModel()
    viewModel.selection = PulseDemoView.metadata.id
    viewModel.handleURL(URL(string: "x-demo://next")!, urlScheme: "x-demo")
    #expect(viewModel.selection == GrassSphereDemoView.metadata.id)
    viewModel.handleURL(URL(string: "x-demo://previous")!, urlScheme: "x-demo")
    #expect(viewModel.selection == PulseDemoView.metadata.id)
}
