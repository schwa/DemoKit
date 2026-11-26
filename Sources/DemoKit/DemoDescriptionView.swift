import SwiftUI

struct DescriptionOverlayFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = value ?? nextValue()
    }
}

// Set by a configuration inspector that draws the description overlay itself, so the overlay
// covers only the demo and not the inspector column.
struct DescriptionOverlayHandledKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension EnvironmentValues {
    @Entry var demoDescriptionMetadata: DemoMetadata?
}

struct DemoDescriptionContainer<Content: View>: View {
    let metadata: DemoMetadata
    let content: Content

    @AppStorage("showDemoDescription")
    private var showDescription = false

    @State
    private var overlayHandledByContent = false

    var body: some View {
        content
            .environment(\.demoDescriptionMetadata, metadata)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onPreferenceChange(DescriptionOverlayHandledKey.self) { value in
                overlayHandledByContent = value
            }
            .modifier(DemoDescriptionOverlay(metadata: overlayHandledByContent ? nil : metadata))
            .toolbar {
                if metadata.hasDescription {
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
}

struct DemoDescriptionOverlay: ViewModifier {
    let metadata: DemoMetadata?

    @AppStorage("showDemoDescription")
    private var showDescription = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showDescription, let metadata, metadata.hasDescription {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(metadata.name, systemImage: metadata.systemImage)
                                .font(.title.bold())
                                .foregroundStyle(metadata.color ?? .primary)
                            if let description = metadata.description {
                                Text(LocalizedStringKey(description))
                                    .font(.title2)
                            }
                            if let longDescription = metadata.longDescription {
                                Text(LocalizedStringKey(longDescription))
                                    .font(.title3)
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: 600, maxHeight: 300)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(key: DescriptionOverlayFrameKey.self, value: proxy.frame(in: .global))
                        }
                    }
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.default, value: showDescription)
    }
}

extension DemoMetadata {
    var hasDescription: Bool {
        showsDescriptionButton && (description != nil || longDescription != nil)
    }
}
