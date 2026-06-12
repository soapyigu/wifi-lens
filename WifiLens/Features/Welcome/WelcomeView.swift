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
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .padding(.bottom, Layout.descriptionH)

            // Title
            Text("Wi-Fi Lens")
                .font(Typography.display)
                .foregroundColor(.primary)
                .padding(.bottom, Layout.rowGap)

            // Description
            Text("Point your camera at a router label or Wi-Fi card. We'll detect the network and connect.")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Layout.descriptionH)

            Spacer()

            // Start Scanning button
            Button(action: onStartScanning) {
                Text("Start Scanning")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.buttonPaddingV)
                    .background(Palette.accent)
                    .cornerRadius(Layout.buttonRadius)
            }
            .padding(.horizontal, Layout.screenH)
            .padding(.bottom, Layout.buttonSpacing)

            Text("Processing happens on-device")
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, Layout.bottomSafe)
        }
        .background(Palette.cardFill)
    }
}

#Preview {
    WelcomeView(onStartScanning: {})
}
