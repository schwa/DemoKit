import SwiftUI

struct DemoDescriptionContainer<Content: View>: View {
    let metadata: DemoMetadata
    let content: Content

    @AppStorage("showDemoDescription")
    private var showDescription = false

    var body: some View {
        content
            .overlay(alignment: .top) {
                if showDescription, hasDescription {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metadata.name)
                                .font(.headline)
                            if let description = metadata.description {
                                Text(description)
                                    .foregroundStyle(.secondary)
                            }
                            if let longDescription = metadata.longDescription {
                                Text(longDescription)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .frame(maxHeight: 300)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
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
                    }
                }
            }
    }

    private var hasDescription: Bool {
        metadata.description != nil || metadata.longDescription != nil
    }
}
