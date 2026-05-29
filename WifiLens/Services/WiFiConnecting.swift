import Foundation

protocol WiFiConnecting: Sendable {
    func connect(ssid: String, password: String) async -> Bool
}

struct LiveWiFiConnector: WiFiConnecting {
    func connect(ssid: String, password: String) async -> Bool {
        await WiFiConnector.connect(ssid: ssid, password: password)
    }
}
