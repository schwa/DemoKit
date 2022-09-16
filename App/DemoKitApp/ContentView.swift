@_spi(DemoKit) import DemoKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        DemosView {
            AnyDemo("Red Demo") {
                Color.red
            }
            .tagged(["red"])
            AnyDemo("Green Demo") {
                Color.green
            }
            .tagged(["green"])
            AnyDemo("Blue Demo") {
                Color.blue
            }
            .tagged(["blue"])
            AnyDemo("Crashing Demo") {
                fatalError()
            }
            AnyDemo("Crashing Demo 2") {
                fatalError()
            }
        }
    }
}
