//
//  WifiLensApp.swift
//  WifiLens
//
//  Created by Yi Gu on 2/18/26.
//

import SwiftUI
import UIKit

@main
struct WifiLensApp: App {
    @State private var screen: AppScreen = .welcome
    @State private var lastSnapshot: UIImage?
    @State private var lastCredentials: (ssid: String, password: String)?

    var body: some Scene {
        WindowGroup {
            screenView
                .animation(.easeInOut(duration: 0.1), value: screen)
        }
    }

    @ViewBuilder
    private var screenView: some View {
        switch screen {
        case .welcome:
            WelcomeView(onStartScanning: {
                screen = .scanning
            })

        case .scanning:
            ScanningView(
                onCancel: { screen = .welcome },
                onCredentialsFound: { ssid, password, snapshot in
                    lastSnapshot = snapshot
                    lastCredentials = (ssid, password)
                    screen = .foundDetails(ssid: ssid, password: password)
                }
            )

        case .foundDetails(let ssid, let password):
            FoundDetailsView(
                networkName: ssid,
                password: password,
                backgroundImage: lastSnapshot,
                onRescan: {
                    lastSnapshot = nil
                    lastCredentials = nil
                    screen = .scanning
                },
                onConnect: { editedSSID, editedPassword in
                    lastCredentials = (editedSSID, editedPassword)
                    screen = .connecting(networkName: editedSSID)
                }
            )

        case .connecting(let networkName):
            ZStack {
                if let creds = lastCredentials {
                    FoundDetailsView(
                        networkName: creds.ssid,
                        password: creds.password,
                        backgroundImage: lastSnapshot,
                        onRescan: { },
                        onConnect: { _, _ in }
                    )
                }
                ConnectingView(networkName: networkName)
            }
            .task {
                guard let creds = lastCredentials else {
                    screen = .connectFail(networkName: networkName, ssid: networkName, password: "")
                    return
                }
                let success = await WiFiConnector.connect(ssid: creds.ssid, password: creds.password)
                screen = success
                    ? .connectSuccess(networkName: networkName)
                    : .connectFail(networkName: networkName, ssid: creds.ssid, password: creds.password)
            }

        case .connectSuccess(let networkName):
            ConnectSuccessView(
                networkName: networkName,
                onDone: { screen = .welcome },
                onScanAnother: {
                    lastSnapshot = nil
                    lastCredentials = nil
                    screen = .scanning
                }
            )

        case .connectFail(let networkName, _, _):
            ConnectFailView(
                networkName: networkName,
                onTryAgain: { screen = .connecting(networkName: networkName) },
                onScanAnother: {
                    lastSnapshot = nil
                    lastCredentials = nil
                    screen = .scanning
                }
            )
        }
    }
}
