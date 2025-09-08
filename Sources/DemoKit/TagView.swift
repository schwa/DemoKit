import SwiftUI

struct TagView: View {
    var text: String

    var body: some View {
        Text(text)
            .fixedSize()
            .font(.caption)
            .foregroundStyle(.white)
            .padding([.leading, .trailing], 4)
            .padding([.top, .bottom], 2)
            .background(Color.accentColor, in: Capsule())
    }
}
