@_spi(DemoKit) import DemoKit
import SwiftUI

struct ContentView: View {
    var body: some View {
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
            AnyDemo("Crashing Demo") {
                fatalError()
            }
            AnyDemo("Crashing Demo 2") {
                fatalError()
            }
        }
    }
}
