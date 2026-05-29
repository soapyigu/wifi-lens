import UIKit

@MainActor
@Observable
final class AppViewModel {
    private(set) var screen: AppScreen = .welcome
    private(set) var lastSnapshot: UIImage?
    private(set) var lastCredentials: Credentials?

    private let connector: WiFiConnecting
    private var connectTask: Task<Void, Never>?

    init(connector: WiFiConnecting = LiveWiFiConnector()) {
        self.connector = connector
    }

    func startScanning() {
        screen = .scanning
    }

    func cancelScanning() {
        screen = .welcome
    }

    func credentialsFound(ssid: String, password: String, snapshot: UIImage?) {
        let credentials = Credentials(ssid: ssid, password: password)
        lastSnapshot = snapshot
        lastCredentials = credentials
        screen = .foundDetails(ssid: ssid, password: password)
    }

    func rescan() {
        lastSnapshot = nil
        lastCredentials = nil
        screen = .scanning
    }

    func confirmConnect(ssid: String, password: String) {
        let credentials = Credentials(ssid: ssid, password: password)
        lastCredentials = credentials
        screen = .connecting(networkName: ssid)
        runConnect(credentials)
    }

    func tryAgain() {
        guard let credentials = lastCredentials else {
            screen = .welcome
            return
        }
        screen = .connecting(networkName: credentials.ssid)
        runConnect(credentials)
    }

    func done() {
        screen = .welcome
    }

    func scanAnother() {
        lastSnapshot = nil
        lastCredentials = nil
        screen = .scanning
    }

    private func runConnect(_ credentials: Credentials) {
        connectTask?.cancel()
        connectTask = Task { [weak self] in
            guard let self else { return }
            let success = await connector.connect(
                ssid: credentials.ssid,
                password: credentials.password
            )
            guard !Task.isCancelled else { return }
            screen = success
                ? .connectSuccess(networkName: credentials.ssid)
                : .connectFail(
                    networkName: credentials.ssid,
                    ssid: credentials.ssid,
                    password: credentials.password
                )
        }
    }
}
