//
//  AppScreen.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import Foundation

enum AppScreen: Equatable {
    case welcome
    case scanning
    case foundDetails(ssid: String, password: String)
    case connecting(networkName: String)
    case connectSuccess(networkName: String)
    case connectFail(networkName: String, ssid: String, password: String)
}
