import SwiftUI

// MARK: - Preference Key (bool only)

struct HasDemoConfigurationPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - View Modifier

private struct DemoConfigurationModifier<Configuration: View>: ViewModifier {
    @ViewBuilder let configuration: () -> Configuration

    @Environment(\.demoKitConfiguration)
    private var demoKitConfiguration: DemoKitConfiguration

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
        content
            .preference(key: HasDemoConfigurationPreferenceKey.self, value: true)
            .modifier(ConfigurationPresentation(showConfiguration: $showConfiguration, useInspector: effectiveUseInspector, configuration: configuration))
    }
}

private struct ConfigurationPresentation<Configuration: View>: ViewModifier {
    @Binding var showConfiguration: Bool
    let useInspector: Bool
    @ViewBuilder let configuration: () -> Configuration

    func body(content: Content) -> some View {
        if useInspector {
            #if !os(visionOS)
            content
                .inspector(isPresented: $showConfiguration) {
                    ScrollView {
                        configuration()
                            .padding()
                    }
                    .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
                }
            #endif
        } else {
            #if os(macOS)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

public extension View {
    func demoConfiguration<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(DemoConfigurationModifier(configuration: content))
    }
}

// MARK: - Configuration Container

struct DemoConfigurationContainer<Content: View>: View {
    let content: Content

    @State private var hasConfiguration = false
    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    var body: some View {
        content
            .onPreferenceChange(HasDemoConfigurationPreferenceKey.self) { value in
                hasConfiguration = value
            }
            .toolbar {
                if hasConfiguration {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showConfiguration.toggle()
                        } label: {
                            Label("Configuration", systemImage: "gear")
                        }
                        .help("Toggle configuration panel")
                        .accessibilityIdentifier("toggle-configuration")
                    }
                }
            }
    }
}
