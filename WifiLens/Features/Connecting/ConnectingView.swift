//
//  ConnectingView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI

struct ConnectingView: View {
    var networkName: String
    var onSuccess: (String) -> Void
    var onFailure: (String, String) -> Void

    @State private var vm: ConnectingViewModel

    init(vm: ConnectingViewModel,
         networkName: String,
         onSuccess: @escaping (String) -> Void,
         onFailure: @escaping (String, String) -> Void) {
        _vm = State(initialValue: vm)
        self.networkName = networkName
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    var body: some View {
        ZStack {
            Palette.dim
                .ignoresSafeArea()

            VStack(spacing: Layout.sectionGap) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Palette.accent))
                    .scaleEffect(Layout.progressScale)

                Text("Connecting...")
                    .font(Typography.heading)
                    .foregroundColor(.black)

                Text(networkName)
                    .font(Typography.buttonSecondary)
                    .foregroundColor(.black.opacity(0.8))

                Text("Approve the prompt on your device,\nthen we'll verify the connection.")
                    .font(Typography.footnote)
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(Layout.screenH)
            .background(Palette.sheetSurface)
            .cornerRadius(Layout.dialogRadius)
            .padding(.horizontal, Layout.bottomSafe)
        }
        .onAppear {
            vm.onSuccess = onSuccess
            vm.onFailure = onFailure
            vm.connect()
        }
        .onDisappear {
            vm.cancel()
        }
    }
}
