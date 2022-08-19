import SwiftUI
import DemoKit

struct ContentView: View {
    var body: some View {
        //UserDefaultsView()

        DemosView {
            AnyDemo("Red Demo") {
                Color.red
            }
            AnyDemo("Green Demo") {
                Color.green
            }
            AnyDemo("Blue Demo") {
                Color.blue
            }
        }
    }
}

