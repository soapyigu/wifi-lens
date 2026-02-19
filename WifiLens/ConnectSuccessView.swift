//
//  ConnectSuccessView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/18/26.
//

import SwiftUI

struct ConnectSuccessView: View {
    var networkName: String
    var onDone: () -> Void
    var onScanAnother: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Success icon
            Image("ConnectSuccess")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.bottom, 32)

            // Success title
            Text("Connected!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 12)

            // Network name
            Text("Successfully connected to")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Text(networkName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.top, 4)

            Spacer()

            // Done button
            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            // Scan another network
            Button(action: onScanAnother) {
                Text("Scan Another")
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
    ConnectSuccessView(
        networkName: "HomeNetwork_5G",
        onDone: {},
        onScanAnother: {}
    )
}
