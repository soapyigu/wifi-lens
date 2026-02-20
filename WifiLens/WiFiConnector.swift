//
//  WiFiConnector.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import NetworkExtension

struct WiFiConnector {
    static func connect(ssid: String, password: String) async -> Bool {
        let config = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        config.joinOnce = false

        return await withCheckedContinuation { continuation in
            NEHotspotConfigurationManager.shared.apply(config) { error in
                if let error = error as NSError? {
                    // "Already associated" means the device is already on this network — treat as success
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
