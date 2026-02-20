//
//  WelcomeView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/18/26.
//

import SwiftUI

struct WelcomeView: View {
    var onStartScanning: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Wi-Fi icon
            Image("wifi")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.bottom, 40)

            // Title
            Text("Wi-Fi Lens")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 16)

            // Description
            Text("Point your camera at a router label or Wi-Fi card. We'll detect the network and connect.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()

            // Start Scanning button
            Button(action: onStartScanning) {
                Text("Start Scanning")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            Text("Processing happens on-device")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    WelcomeView(onStartScanning: {})
}
