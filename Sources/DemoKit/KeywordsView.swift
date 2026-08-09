import SwiftUI

struct KeywordsView: View {
    let keywords: [String]
    var selectedKeyword: String?
    var onTap: ((String) -> Void)?

    var body: some View {
        OverflowingHStack {
            ForEach(keywords, id: \.self) { keyword in
                let isSelected = selectedKeyword?.caseInsensitiveCompare(keyword) == .orderedSame
                if let onTap {
                    Button {
                        onTap(keyword)
                    } label: {
                        TagView(text: keyword, isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .help(isSelected ? "Clear the \(keyword) filter" : "Show only demos tagged \(keyword)")
                    .accessibilityLabel(isSelected ? "Clear \(keyword) filter" : "Filter by \(keyword)")
                }
                else {
                    TagView(text: keyword, isSelected: isSelected)
                }
            }
        }
        .accessibilityHidden(onTap == nil)
    }
}
