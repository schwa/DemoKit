import SwiftUI

struct TagView: View {
    var text: String
    var isSelected = false

    var body: some View {
        Text(text)
            .fixedSize()
            .font(.caption)
            .foregroundStyle(isSelected ? Color.accentColor : .white)
            .padding([.leading, .trailing], 4)
            .padding([.top, .bottom], 2)
            .background(isSelected ? AnyShapeStyle(.background) : AnyShapeStyle(Color.accentColor), in: Capsule())
            .overlay {
                if isSelected {
                    Capsule().strokeBorder(Color.accentColor, lineWidth: 1)
                }
            }
    }
}
