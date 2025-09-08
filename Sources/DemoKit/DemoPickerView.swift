import SwiftUI

public struct DemoPickerView: View {
    @State private var viewModel: DemoPickerViewModel
    @Environment(\.demoURLScheme) private var urlScheme

    public init(demos: [any DemoView.Type]) {
        self._viewModel = State(initialValue: DemoPickerViewModel(demos: demos))
    }

    public var body: some View {
        DemosNavigationSplitView()
            .environment(viewModel)
            .onOpenURL { url in
                viewModel.handleURL(url, urlScheme: urlScheme)
            }
    }
}
