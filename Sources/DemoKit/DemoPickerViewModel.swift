import SwiftUI
import Observation

@Observable
@MainActor
public final class DemoPickerViewModel {
    public let demos: [any DemoView.Type]
    public var selection: DemoMetadata.ID?
    
    @ObservationIgnored
    @AppStorage("demoview")
    private var storedSelection: String = "" {
        didSet {
            if storedSelection != selection?.rawValue {
                loadStoredSelection()
            }
        }
    }
    
    public init(demos: [any DemoView.Type]) {
        self.demos = demos
        loadInitialSelection()
    }
    
    private func loadInitialSelection() {
        let elements = demos.map { $0.metadata }
        
        // First check environment variable
        if let envSelection = ProcessInfo.processInfo.environment["DEMOVIEW"], 
           !envSelection.isEmpty {
            let envID = DemoMetadata.ID(envSelection)
            if elements.contains(where: { $0.id == envID }) {
                selection = envID
                return
            }
        }
        
        // Then check stored selection
        loadStoredSelection()
    }
    
    private func loadStoredSelection() {
        let elements = demos.map { $0.metadata }
        
        guard !storedSelection.isEmpty else {
            selection = elements.first?.id
            return
        }
        
        let storedID = DemoMetadata.ID(storedSelection)
        if elements.contains(where: { $0.id == storedID }) {
            selection = storedID
        } else {
            selection = elements.first?.id
        }
    }
    
    func selectionDidChange() {
        storedSelection = selection?.rawValue ?? ""
    }
}