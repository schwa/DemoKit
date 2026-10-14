#if os(macOS)
import AppKit
@testable import DemoKit
import SwiftUI
import Testing

@MainActor
struct DemoDescriptionLayoutTests {
    @Test func descriptionContainerFillsProposedSize() {
        let metadata = DemoMetadata(id: .init("small"), name: "Small", description: "A small demo")
        let container = DemoDescriptionContainer(
            metadata: metadata,
            content: Color.red.frame(width: 50, height: 50)
        )
        let controller = NSHostingController(rootView: container)
        let size = controller.sizeThatFits(in: CGSize(width: 800, height: 600))
        #expect(size == CGSize(width: 800, height: 600))
    }
}
#endif
