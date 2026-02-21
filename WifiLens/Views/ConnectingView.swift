//
//  ConnectingView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI

struct ConnectingView: View {
    var networkName: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.4)

                Text("Connecting...")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)

                Text(networkName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))

                Text("Approve the prompt on your device,\nthen we'll verify the connection.")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color(.systemGray6).opacity(0.95))
            .cornerRadius(20)
            .padding(.horizontal, 48)
        }
    }
}

#Preview {
    ConnectingView(networkName: "HomeNetwork_5G")
}
