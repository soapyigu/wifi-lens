//
//  WifiLensApp.swift
//  WifiLens
//
//  Created by Yi Gu on 2/18/26.
//

import SwiftUI

@main
struct WifiLensApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomeView(onStartScanning: {})
        }
    }
}
