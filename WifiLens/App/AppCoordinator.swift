import UIKit

/// Owns navigation (the current `AppScreen`) and the in-flight credentials
/// carried between screens. Feature ViewModels are built via the factory
/// methods so each feature receives the use cases it needs.
@MainActor
@Observable
final class AppCoordinator {
    private(set) var screen: AppScreen = .welcome
    private(set) var lastSnapshot: UIImage?
    private(set) var lastCredentials: Credentials?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    // MARK: - Navigation actions

    func startScanning() {
        screen = .scanning
    }

    func cancelScanning() {
        screen = .welcome
    }

    func credentialsFound(_ credentials: Credentials, snapshot: UIImage?) {
        lastSnapshot = snapshot
        lastCredentials = credentials
        screen = .foundDetails(ssid: credentials.ssid, password: credentials.password)
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
    }

    func connectSucceeded(ssid: String) {
        screen = .connectSuccess(networkName: ssid)
    }

    func connectFailed(ssid: String, password: String) {
        screen = .connectFail(networkName: ssid, ssid: ssid, password: password)
    }

    func tryAgain() {
        guard let credentials = lastCredentials else {
            screen = .welcome
            return
        }
        screen = .connecting(networkName: credentials.ssid)
    }

    func done() {
        screen = .welcome
    }

    func scanAnother() {
        lastSnapshot = nil
        lastCredentials = nil
        screen = .scanning
    }

    // MARK: - Feature VM factories

    func makeScanningViewModel() -> ScanningViewModel {
        ScanningViewModel(scanUseCase: container.scanUseCase)
    }

    func makeConnectingViewModel(credentials: Credentials) -> ConnectingViewModel {
        ConnectingViewModel(
            credentials: credentials,
            connectUseCase: container.connectUseCase
        )
    }
}
