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
    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    func body(content: Content) -> some View {
        content
            .preference(key: HasDemoConfigurationPreferenceKey.self, value: true)
            #if os(macOS)
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
                    }
                }
            }
    }
}
