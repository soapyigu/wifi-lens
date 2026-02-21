//
//  WiFiConnector.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import NetworkExtension

struct WiFiConnector {

    // MARK: - Public

    /// Attempts to join the given network and returns whether the device is
    /// actually connected to it afterwards.
    ///
    /// Root cause of the original bug:
    ///   `NEHotspotConfigurationManager.apply(_:completionHandler:)` fires its
    ///   completion with `nil` error as soon as the **configuration is stored**,
    ///   not when the device has finished joining the network. Real failures
    ///   (wrong password, network unreachable) are shown to the user via a
    ///   system dialog but are never surfaced to the completion handler.
    ///
    /// Fix:
    ///   After `apply` succeeds we wait for iOS to finish the association, then
    ///   call `NEHotspotNetwork.fetchCurrent()` to confirm the device ended up
    ///   on the expected SSID. Requires the `com.apple.developer.networking.wifi-info`
    ///   entitlement (already added to WifiLens.entitlements).
    static func connect(ssid: String, password: String) async -> Bool {
        let config = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        config.joinOnce = false

        // Step 1 — apply the configuration.
        let applyError = await withCheckedContinuation { (continuation: CheckedContinuation<Error?, Never>) in
            NEHotspotConfigurationManager.shared.apply(config) { error in
                continuation.resume(returning: error)
            }
        }

        if let error = applyError as NSError? {
            // `alreadyAssociated` means the device is already on this network.
            // Fall through to verify the SSID rather than returning early.
            guard error.domain == NEHotspotConfigurationErrorDomain,
                  error.code == NEHotspotConfigurationError.alreadyAssociated.rawValue
            else {
                return false   // Framework-level error (invalid config, user denied, etc.)
            }
        }

        // Step 2 — wait for the WiFi association to complete.
        // iOS shows the user a system "Join network?" prompt and then performs
        // the association; this typically finishes within 3-4 seconds.
        try? await Task.sleep(for: .seconds(4))

        // Step 3 — verify we are actually on the target network.
        return await isConnected(to: ssid)
    }

    // MARK: - Private

    /// Returns true only when `NEHotspotNetwork.fetchCurrent()` reports that
    /// the device's active WiFi network matches `targetSSID`.
    private static func isConnected(to targetSSID: String) async -> Bool {
        await withCheckedContinuation { continuation in
            NEHotspotNetwork.fetchCurrent { network in
                continuation.resume(returning: network?.ssid == targetSSID)
            }
        }
    }
}
