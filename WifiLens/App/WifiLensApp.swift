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
    @State private var coordinator: AppCoordinator

    init() {
        let container = AppContainer.live()
        _coordinator = State(initialValue: AppCoordinator(container: container))
    }

    var body: some Scene {
        WindowGroup {
            screenView
                .animation(.easeInOut(duration: Motion.screenTransition), value: coordinator.screen)
        }
    }

    @ViewBuilder
    private var screenView: some View {
        switch coordinator.screen {
        case .welcome:
            WelcomeView(onStartScanning: coordinator.startScanning)

        case .scanning:
            ScanningView(
                vm: coordinator.makeScanningViewModel(),
                onCancel: coordinator.cancelScanning,
                onCredentialsFound: { credentials, snapshot in
                    coordinator.credentialsFound(credentials, snapshot: snapshot)
                }
            )

        case .foundDetails(let ssid, let password):
            FoundDetailsView(
                networkName: ssid,
                password: password,
                backgroundImage: coordinator.lastSnapshot,
                onRescan: coordinator.rescan,
                onConnect: coordinator.confirmConnect
            )

        case .connecting(let networkName):
            ZStack {
                if let creds = coordinator.lastCredentials {
                    FoundDetailsView(
                        networkName: creds.ssid,
                        password: creds.password,
                        backgroundImage: coordinator.lastSnapshot,
                        onRescan: { },
                        onConnect: { _, _ in }
                    )
                    ConnectingView(
                        vm: coordinator.makeConnectingViewModel(credentials: creds),
                        networkName: networkName,
                        onSuccess: coordinator.connectSucceeded,
                        onFailure: coordinator.connectFailed
                    )
                } else {
                    // Missing credentials — fall back to fail screen.
                    Color.clear.task {
                        coordinator.connectFailed(ssid: networkName, password: "")
                    }
                }
            }

        case .connectSuccess(let networkName):
            ConnectSuccessView(
                networkName: networkName,
                onDone: coordinator.done,
                onScanAnother: coordinator.scanAnother
            )

        case .connectFail(let networkName, _, _):
            ConnectFailView(
                networkName: networkName,
                onTryAgain: coordinator.tryAgain,
                onScanAnother: coordinator.scanAnother
            )
        }
    }
}
