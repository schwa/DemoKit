//
//  DemoKitApp.swift
//  DemoKit
//
//  Created by Jonathan Wight on 8/17/22.
//

import SwiftUI

@main
struct DemoKitApp: App {
    
    @AppStorage("LaunchCount")
    var launchCount = 0
    
    init() {
        UserDefaults.standard.set(Date(), forKey: "LaunchDate")
        self.launchCount += 1
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
