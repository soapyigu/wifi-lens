//
//  ConnectFailView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/18/26.
//

import SwiftUI

struct ConnectFailView: View {
    var networkName: String
    var onTryAgain: () -> Void
    var onScanAnother: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Fail icon
            Image("ConnectFail")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.bottom, 32)

            // Failed title
            Text("Connection Failed")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 12)

            // Explanation
            Text("Could not connect to")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Text(networkName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.top, 4)
                .padding(.bottom, 12)

            Text("The password may be incorrect or the network is out of range.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Try Again button
            Button(action: onTryAgain) {
                Text("Try Again")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            // Back to scan
            Button(action: onScanAnother) {
                Text("Back to Scan")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0x36/255, green: 0x41/255, blue: 0x53/255, alpha: 1) : UIColor(red: 0xE5/255, green: 0xE7/255, blue: 0xEB/255, alpha: 1) }))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    ConnectFailView(
        networkName: "HomeNetwork_5G",
        onTryAgain: {},
        onScanAnother: {}
    )
}
