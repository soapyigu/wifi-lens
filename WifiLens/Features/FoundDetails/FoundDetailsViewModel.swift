import Foundation

@MainActor
@Observable
final class FoundDetailsViewModel {
    var networkName: String
    var password: String
    var isPasswordVisible: Bool = false

    init(ssid: String, password: String) {
        self.networkName = ssid
        self.password = password
    }
}
