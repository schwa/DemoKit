@_spi(DemoKit) import DemoKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        // UserDefaultsView()

//        DemosView {
//            AnyDemo("Red Demo") {
//                Color.red
//            }
//            AnyDemo("Green Demo") {
//                Color.green
//            }
//            AnyDemo("Blue Demo") {
//                Color.blue
//            }
//        }

        CrashDetectionView(id: "test", unstableTime: 1, showLifeCycle: true) {
            VStack {
                Text("Hello world")
                Button("Crash") {
                    fatalError()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
