import Foundation

protocol CredentialParsing: Sendable {
    func parse(_ transcripts: [String]) -> Credentials?
    func partialMatch(_ transcripts: [String]) -> PartialCredentials
}

struct LiveCredentialParser: CredentialParsing {
    func parse(_ transcripts: [String]) -> Credentials? {
        guard let raw = WiFiCredentialParser.parse(transcripts) else { return nil }
        return Credentials(ssid: raw.ssid, password: raw.password)
    }

    func partialMatch(_ transcripts: [String]) -> PartialCredentials {
        let raw = WiFiCredentialParser.partialMatch(transcripts)
        return PartialCredentials(ssid: raw.ssid, password: raw.password)
    }
}
