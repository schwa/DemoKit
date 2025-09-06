import SwiftUI

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
