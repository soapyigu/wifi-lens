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
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .padding(.bottom, Layout.screenH)

            // Success title
            Text("Connected!")
                .font(Typography.title)
                .foregroundColor(.primary)
                .padding(.bottom, Layout.buttonSpacing)

            // Network name
            Text("Successfully connected to **\(networkName)**")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.descriptionH)

            Spacer()

            // Done button
            Button(action: onDone) {
                Text("Done")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.buttonPaddingV)
                    .background(Palette.accent)
                    .cornerRadius(Layout.buttonRadius)
            }
            .padding(.horizontal, Layout.screenH)
            .padding(.bottom, Layout.buttonSpacing)

            // Scan another network
            Button(action: onScanAnother) {
                Text("Scan Another")
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
    ConnectSuccessView(
        networkName: "HomeNetwork_5G",
        onDone: {},
        onScanAnother: {}
    )
}
