import SwiftUI

struct DemoDescriptionContainer<Content: View>: View {
    let metadata: DemoMetadata
    let content: Content

    @AppStorage("showDemoDescription")
    private var showDescription = false

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if showDescription, hasDescription {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metadata.name)
                                .font(.title.bold())
                            if let description = metadata.description {
                                Text(LocalizedStringKey(description))
                                    .font(.title2)
                            }
                            if let longDescription = metadata.longDescription {
                                Text(LocalizedStringKey(longDescription))
                                    .font(.title3)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .frame(maxHeight: 300)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.default, value: showDescription)
            .toolbar {
                if hasDescription {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showDescription.toggle()
                        } label: {
                            Label("Description", systemImage: "info.circle")
                        }
                        .help("Toggle description overlay")
                        .accessibilityIdentifier("toggle-description")
                    }
                }
            }
    }

    private var hasDescription: Bool {
        metadata.description != nil || metadata.longDescription != nil
    }
}
