import Foundation

/// Composition root. Built once at app launch (`AppContainer.live()`); holds
/// the use cases each feature VM depends on. Plain struct — no DI framework.
@MainActor
struct AppContainer {
    let scanUseCase: ScanForCredentialsUseCase
    let connectUseCase: ConnectToWiFiUseCase

    static func live() -> AppContainer {
        let parser = LiveCredentialParser()
        let scanner = LiveCredentialScanner(parser: parser)
        let connector = LiveWiFiConnector()

        return AppContainer(
            scanUseCase: LiveScanForCredentialsUseCase(scanner: scanner),
            connectUseCase: LiveConnectToWiFiUseCase(connector: connector)
        )
    }
}
