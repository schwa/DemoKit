@_spi(DemoKit) import DemoKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        DemosView {
            AnyDemo("Red Demo") {
                Color.red
            }
            .tagged(["red"])
            .grouped("Color")
            AnyDemo("Green Demo") {
                Color.green
            }
            .tagged(["green"])
            .grouped("Color")
            AnyDemo("Blue Demo") {
                Color.blue
            }
            .tagged(["blue"])
            .grouped("Color")

            AnyDemo("Crashing Demo") {
                fatalError()
            }
            .grouped("Dodgy")
            
            AnyDemo("Crashing Demo 2") {
                fatalError()
            }
            .grouped("Dodgy")
        }
    }
}
