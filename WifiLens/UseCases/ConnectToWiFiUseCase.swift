import Foundation

/// Business action: apply a WiFi configuration and verify association.
/// Implements the Facade pattern over the `WiFiConnecting` service.
protocol ConnectToWiFiUseCase: Sendable {
    func execute(_ credentials: Credentials) async -> Bool
}

struct LiveConnectToWiFiUseCase: ConnectToWiFiUseCase {
    let connector: WiFiConnecting

    func execute(_ credentials: Credentials) async -> Bool {
        await connector.connect(ssid: credentials.ssid, password: credentials.password)
    }
}
