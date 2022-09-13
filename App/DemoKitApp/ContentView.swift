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
        }

        // UserDefaultsView()

//        CrashDetectionView(id: "test", unstableTime: 1, showLifeCycle: true) {
//            VStack {
//                Text("Hello world")
//                Button("Crash") {
//                    fatalError()
//                }
//            }
//            .padding()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
    }
}
