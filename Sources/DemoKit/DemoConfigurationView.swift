import SwiftUI

// MARK: - Preference Key

struct DemoConfigurationPreferenceKey: PreferenceKey {
    static let defaultValue: EquatableAnyView? = nil

    static func reduce(value: inout EquatableAnyView?, nextValue: () -> EquatableAnyView?) {
        if let next = nextValue() {
            value = next
        }
    }
}

@MainActor
struct EquatableAnyView: Equatable {
    nonisolated(unsafe) let id: AnyHashable
    let content: AnyView

    init<Content: View>(id: AnyHashable = ObjectIdentifier(Content.self), @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = AnyView(content())
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - View Modifier

public extension View {
    func demoConfiguration<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        self.preference(key: DemoConfigurationPreferenceKey.self, value: EquatableAnyView(content: content))
    }
}

// MARK: - Configuration Container

struct DemoConfigurationContainer<Content: View>: View {
    let content: Content

    @State private var configurationView: EquatableAnyView?
    @AppStorage("showDemoConfiguration")
    private var showConfiguration = false

    var body: some View {
        content
            .onPreferenceChange(DemoConfigurationPreferenceKey.self) { value in
                configurationView = value
            }
            .toolbar {
                if configurationView != nil {
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
            #if os(macOS)
            .overlay(alignment: .bottom) {
                if showConfiguration, let configurationView {
                    configurationView.content
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: showConfiguration)
            #else
            .sheet(isPresented: $showConfiguration) {
                if let configurationView {
                    NavigationStack {
                        configurationView.content
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
            }
            #endif
    }
}
