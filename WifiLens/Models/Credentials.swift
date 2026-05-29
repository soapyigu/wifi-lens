import Foundation

struct Credentials: Equatable, Hashable {
    let ssid: String
    let password: String
}

struct PartialCredentials: Equatable {
    let ssid: String?
    let password: String?

    static let empty = PartialCredentials(ssid: nil, password: nil)
}
