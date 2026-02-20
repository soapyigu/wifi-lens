//
//  WiFiConnector.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import NetworkExtension
import Network

struct WiFiConnector {
    static func connect(ssid: String, password: String) async -> Bool {
        let config = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        config.joinOnce = false

        // Step 1: Apply the configuration
        return await withCheckedContinuation { continuation in
            NEHotspotConfigurationManager.shared.apply(config) { error in
                if let error = error as NSError? {
                    // Already on this network — counts as success
                    if error.domain == NEHotspotConfigurationErrorDomain,
                       error.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }
}
