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
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .padding(.bottom, Layout.screenH)

            // Failed title
            Text("Connection Failed")
                .font(Typography.title)
                .foregroundColor(.primary)
                .padding(.bottom, Layout.buttonSpacing)

            // Explanation
            Text("Could not connect to **\(networkName)**")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.descriptionH)
                .padding(.bottom, Layout.buttonSpacing)

            Text("The password may be incorrect or the network is out of range.")
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.descriptionH)

            Spacer()

            // Try Again button
            Button(action: onTryAgain) {
                Text("Try Again")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.buttonPaddingV)
                    .background(Palette.accent)
                    .cornerRadius(Layout.buttonRadius)
            }
            .padding(.horizontal, Layout.screenH)
            .padding(.bottom, Layout.buttonSpacing)

            // Back to scan
            Button(action: onScanAnother) {
                Text("Back to Scan")
                    .font(Typography.buttonSecondary)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.buttonPaddingV)
                    .background(Palette.secondaryButton)
                    .cornerRadius(Layout.buttonRadius)
            }
            .padding(.horizontal, Layout.screenH)
            .padding(.bottom, Layout.bottomSafe)
        }
        .background(Palette.cardFill)
    }
}

#Preview {
    ConnectFailView(
        networkName: "HomeNetwork_5G",
        onTryAgain: {},
        onScanAnother: {}
    )
}
