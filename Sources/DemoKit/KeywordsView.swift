import SwiftUI

struct KeywordsView: View {
    let keywords: [String]

    var body: some View {
        OverflowingHStack {
            ForEach(keywords, id: \.self) { keyword in
                TagView(text: keyword)
            }
        }
    }
}

