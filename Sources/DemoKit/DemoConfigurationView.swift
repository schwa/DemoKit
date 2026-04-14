import SwiftUI

// MARK: - Preference Key (bool only)

struct HasDemoConfigurationPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - Observable store for passing configuration content up the view tree

@Observable
@MainActor
final class DemoConfigurationStore {
    var content: AnyView?
}

// MARK: - View Modifier (applied by demos via .demoConfiguration { ... })

private struct DemoConfigurationModifier<Configuration: View>: ViewModifier {
    @ViewBuilder let configuration: () -> Configuration

    @Environment(\.demoKitConfiguration)
    private var demoKitConfiguration: DemoKitConfiguration

    @Environment(DemoConfigurationStore.self)
    private var store: DemoConfigurationStore?

    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    private var effectiveUseInspector: Bool {
        #if os(visionOS)
        return false
        #else
        return demoKitConfiguration.useInspector
        #endif
    }

    func body(content: Content) -> some View {
        if effectiveUseInspector {
            content
                .preference(key: HasDemoConfigurationPreferenceKey.self, value: true)
                .onAppear {
                    store?.content = AnyView(configuration())
                }
        } else {
            content
                .preference(key: HasDemoConfigurationPreferenceKey.self, value: true)
                .modifier(ConfigurationOverlayPresentation(showConfiguration: $showConfiguration, configuration: configuration))
        }
    }
}

// MARK: - Overlay/Sheet presentation (non-inspector mode)

private struct ConfigurationOverlayPresentation<Configuration: View>: ViewModifier {
    @Binding var showConfiguration: Bool
    @ViewBuilder let configuration: () -> Configuration

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .overlay(alignment: .bottom) {
                if showConfiguration {
                    configuration()
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: showConfiguration)
        #else
        content
            .sheet(isPresented: $showConfiguration) {
                NavigationStack {
                    configuration()
                        .padding()
                        .navigationTitle("Configuration")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showConfiguration = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
        #endif
    }
}

public extension View {
    func demoConfiguration<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(DemoConfigurationModifier(configuration: content))
    }
}
