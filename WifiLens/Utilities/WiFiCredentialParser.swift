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
    /// Always returns the FIRST pair: find the first SSID, then find the
    /// nearest password at or after that line (not the globally first password).
    static func parse(_ transcripts: [String]) -> (ssid: String, password: String)? {
        let lines = normalizedLines(from: transcripts)
        guard let (ssid, ssidLineIdx) = extractValueWithLineIndex(for: ssidKeywords, in: lines) else { return nil }

        // Primary: search at or after the SSID line (correct reading order)
        // Fallback: search before the SSID line (handles OCR returning items out of order)
        let password = extractValue(for: passwordKeywords, in: Array(lines[ssidLineIdx...]))
                    ?? extractValue(for: passwordKeywords, in: Array(lines[..<ssidLineIdx]))
        guard let password else { return nil }

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
        "network", "wireless network", "wlan", "ap name", "wi-fi", "name", "wifi",
        // Chinese
        "网络名称", "无线网络名称", "wifi名称", "网络名", "ssid名称",
        // Japanese
        "ネットワーク名", "wi-fi名",
        // Korean
        "네트워크 이름", "wi-fi 이름"
    ]

    private static let passwordKeywords: [String] = [
        "password", "pass", "passphrase", "wpa key", "wpa2 key",
        "wpa psk", "wpa2 psk", "key", "wifi password", "wi-fi password",
        "wireless password", "network key", "security key", "pwd",
        // Chinese
        "密码", "无线密码", "wifi密码", "网络密钥", "安全密钥",
        // Japanese
        "パスワード", "暗号化キー", "セキュリティキー",
        // Korean
        "비밀번호", "보안 키"
    ]

    // MARK: - Line Normalization

    private static func normalizedLines(from transcripts: [String]) -> [String] {
        transcripts
            .flatMap { $0.components(separatedBy: "\n") }
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                  .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            }
            .filter { !$0.isEmpty }
    }

    // MARK: - Value Extraction

    /// Same as extractValue but also returns the line index where the keyword was found.
    private static func extractValueWithLineIndex(for keywords: [String], in lines: [String]) -> (String, Int)? {
        for (index, line) in lines.enumerated() {
            for keyword in keywords {
                guard let keyRange = line.range(of: keyword, options: .caseInsensitive) else { continue }

                let afterKeyword = String(line[keyRange.upperBound...])
                    .trimmingCharacters(in: .whitespaces)

                if afterKeyword.hasPrefix(":") || afterKeyword.hasPrefix("=") {
                    let value = String(afterKeyword.dropFirst())
                        .trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty { return (trimAtNextField(value), index) }
                    if index + 1 < lines.count {
                        let nextLine = stripLeadingSeparator(lines[index + 1])
                        if !nextLine.isEmpty && !isLikelyLabelLine(nextLine) { return (nextLine, index) }
                    }
                } else if afterKeyword.isEmpty {
                    if index + 1 < lines.count {
                        let nextLine = stripLeadingSeparator(lines[index + 1])
                        if !nextLine.isEmpty && !isLikelyLabelLine(nextLine) { return (nextLine, index) }
                    }
                } else if !isLikelyLabelLine(afterKeyword) {
                    return (trimAtNextField(afterKeyword), index)
                }
            }
        }
        return nil
    }

    private static func extractValue(for keywords: [String], in lines: [String]) -> String? {
        for (index, line) in lines.enumerated() {
            for keyword in keywords {
                guard let keyRange = line.range(of: keyword, options: .caseInsensitive) else { continue }

                let afterKeyword = String(line[keyRange.upperBound...])
                    .trimmingCharacters(in: .whitespaces)

                // Strategy 1: separator right after keyword — "wifi: Coffee_Bar!"
                if afterKeyword.hasPrefix(":") || afterKeyword.hasPrefix("=") {
                    let value = String(afterKeyword.dropFirst())
                        .trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty {
                        return trimAtNextField(value)
                    }
                    // Separator present but empty value — fall to next-line strategy
                    if index + 1 < lines.count {
                        let nextLine = stripLeadingSeparator(lines[index + 1])
                        if !nextLine.isEmpty && !isLikelyLabelLine(nextLine) { return nextLine }
                    }
                }
                // Strategy 2: keyword alone on line, value on next line — "wifi\nCoffee_Bar!"
                // Also handles OCR splitting "wifi: value" into ["wifi", ": value"]
                else if afterKeyword.isEmpty {
                    if index + 1 < lines.count {
                        let nextLine = stripLeadingSeparator(lines[index + 1])
                        if !nextLine.isEmpty && !isLikelyLabelLine(nextLine) { return nextLine }
                    }
                }
                // Strategy 3: space-separated — "wifi Coffee_Bar!"
                else if !isLikelyLabelLine(afterKeyword) {
                    return trimAtNextField(afterKeyword)
                }
            }
        }
        return nil
    }

    /// Truncates value at the next "keyword:" boundary on the same line.
    /// e.g. "Coffee_Bar! pwd: 123@5pay?" → "Coffee_Bar!"
    private static func trimAtNextField(_ value: String) -> String {
        var truncateAt = value.endIndex
        for kw in ssidKeywords + passwordKeywords {
            if let kwRange = value.range(of: kw, options: .caseInsensitive) {
                let afterKw = String(value[kwRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                if afterKw.hasPrefix(":") || afterKw.hasPrefix("=") {
                    if kwRange.lowerBound < truncateAt {
                        truncateAt = kwRange.lowerBound
                    }
                }
            }
        }
        return String(value[..<truncateAt]).trimmingCharacters(in: .whitespaces)
    }

    /// Strips a leading ":" or "=" (and surrounding whitespace) that OCR sometimes
    /// attaches to a value token when the label and value are recognised separately.
    /// e.g. ": coffee_bar!" → "coffee_bar!"
    private static func stripLeadingSeparator(_ s: String) -> String {
        guard s.hasPrefix(":") || s.hasPrefix("=") else { return s }
        return String(s.dropFirst()).trimmingCharacters(in: .whitespaces)
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
