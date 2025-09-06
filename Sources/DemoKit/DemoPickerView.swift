import SwiftUI

public struct DemoPickerView: View {
    let demos: [any DemoView.Type]

    public init(demos: [any DemoView.Type]) {
        self.demos = demos
    }

    public var body: some View {
        DemosNavigationSplitView(demos: demos)
    }
}

