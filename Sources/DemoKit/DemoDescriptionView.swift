import SwiftUI

struct DemoDescriptionContainer<Content: View>: View {
    let metadata: DemoMetadata
    let content: Content

    @Environment(\.demoKitConfiguration)
    private var demoKitConfiguration: DemoKitConfiguration

    @AppStorage("showDemoDescription")
    private var showDescription = false

    private var effectiveUseInspector: Bool {
        #if os(visionOS)
        return false
        #else
        return demoKitConfiguration.useInspector
        #endif
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(DescriptionPresentation(metadata: metadata, showDescription: $showDescription, useInspector: effectiveUseInspector))
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

private struct DescriptionPresentation: ViewModifier {
    let metadata: DemoMetadata
    @Binding var showDescription: Bool
    let useInspector: Bool

    @ViewBuilder
    private var descriptionContent: some View {
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

    func body(content: Content) -> some View {
        if useInspector {
            #if !os(visionOS)
            content
                .inspector(isPresented: $showDescription) {
                    ScrollView {
                        descriptionContent
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
                }
            #endif
        } else {
            content
                .overlay(alignment: .top) {
                    if showDescription {
                        ScrollView {
                            descriptionContent
                        }
                        .frame(maxWidth: 600, maxHeight: 300)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.default, value: showDescription)
        }
    }
}
