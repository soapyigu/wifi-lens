//
//  WiFiCredentialParser.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import Foundation

struct WiFiCredentialParser {

    // MARK: - Public Interface

    /// Returns (ssid, password) when both are found with confidence.
    static func parse(_ transcripts: [String]) -> (ssid: String, password: String)? {
        let lines = normalizedLines(from: transcripts)
        guard let ssid = extractValue(for: ssidKeywords, in: lines),
              let password = extractValue(for: passwordKeywords, in: lines)
        else { return nil }

        guard ssid.count >= 2,
              password.count >= 8,
              !isLikelyKeyword(ssid),
              !isLikelyKeyword(password)
        else { return nil }

        return (ssid: ssid, password: password)
    }

    /// Partial match — used to update "still scanning" UI indicators.
    static func partialMatch(_ transcripts: [String]) -> (ssid: String?, password: String?) {
        let lines = normalizedLines(from: transcripts)
        return (
            ssid: extractValue(for: ssidKeywords, in: lines),
            password: extractValue(for: passwordKeywords, in: lines)
        )
    }

    // MARK: - Keywords

    private static let ssidKeywords: [String] = [
        "ssid", "network name", "wi-fi name", "wifi name",
        "network", "wireless network", "wlan", "ap name"
    ]

    private static let passwordKeywords: [String] = [
        "password", "pass", "passphrase", "wpa key", "wpa2 key",
        "wpa psk", "wpa2 psk", "key", "wifi password", "wi-fi password",
        "wireless password", "network key", "security key"
    ]

    // MARK: - Line Normalization

    private static func normalizedLines(from transcripts: [String]) -> [String] {
        transcripts
            .flatMap { $0.components(separatedBy: "\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Value Extraction

    private static func extractValue(for keywords: [String], in lines: [String]) -> String? {
        for (index, line) in lines.enumerated() {
            let lowered = line.lowercased()
            for keyword in keywords {
                guard lowered.contains(keyword) else { continue }

                // Strategy 1: same-line after ':' or '='
                if let value = inlineSuffix(of: line) {
                    return value
                }

                // Strategy 2: next line as value
                if index + 1 < lines.count {
                    let nextLine = lines[index + 1]
                    if !isLikelyLabelLine(nextLine) {
                        return nextLine
                    }
                }
            }
        }
        return nil
    }

    private static func inlineSuffix(of line: String) -> String? {
        for separator in [":", "="] {
            if let range = line.range(of: separator, options: .backwards) {
                let suffix = line[range.upperBound...]
                    .trimmingCharacters(in: .whitespaces)
                if !suffix.isEmpty {
                    return suffix
                }
            }
        }
        return nil
    }

    private static func isLikelyLabelLine(_ line: String) -> Bool {
        let lowered = line.lowercased()
        return (ssidKeywords + passwordKeywords).contains { lowered.contains($0) }
    }

    private static func isLikelyKeyword(_ value: String) -> Bool {
        let lowered = value.lowercased()
        return (ssidKeywords + passwordKeywords).contains { $0 == lowered }
    }
}
