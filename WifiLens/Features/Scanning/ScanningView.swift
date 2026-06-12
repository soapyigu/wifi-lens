//
//  ScanningView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI
import UIKit

struct ScanningView: View {
    var onCancel: () -> Void
    var onCredentialsFound: (Credentials, UIImage?) -> Void

    @State private var vm: ScanningViewModel
    @State private var scanLineOffset: CGFloat = 0

    init(vm: ScanningViewModel,
         onCancel: @escaping () -> Void,
         onCredentialsFound: @escaping (Credentials, UIImage?) -> Void) {
        _vm = State(initialValue: vm)
        self.onCancel = onCancel
        self.onCredentialsFound = onCredentialsFound
    }

    private var scanningStatusText: LocalizedStringKey {
        switch vm.status {
        case .looking:
            return "Looking for Wi-Fi name\nand password..."
        case .sawSSID:
            return "Found network name —\nlooking for password..."
        case .sawPassword:
            return "Found password —\nlooking for network name..."
        case .sawBoth:
            return "Both fields detected —\nhold steady to confirm..."
        case .confirmed:
            return "Found Wi-Fi details!"
        }
    }

    var body: some View {
        ZStack {
            // Camera feed (hosted by the scanner service via VM)
            DataScannerView(controller: vm.cameraScene)
                .ignoresSafeArea()

            // Dark overlay outside the viewfinder cutout
            Palette.overlay
                .ignoresSafeArea()
                .mask(
                    Rectangle()
                        .ignoresSafeArea()
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.viewfinderRadius)
                                .frame(width: Layout.viewfinderSize, height: Layout.viewfinderSize)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                )

            VStack(spacing: 0) {
                // Status label
                Text(scanningStatusText)
                    .font(Typography.statusLabel)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: Motion.statusFade), value: scanningStatusText)
                    .padding(.top, Layout.topTitle)
                    .padding(.horizontal, Layout.screenH)

                Spacer()

                // Viewfinder with corners and scan line
                ZStack {
                    // Animated scan line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Palette.scanLineSoft, Palette.scanLine, Palette.scanLineSoft, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: Layout.viewfinderSize - 8, height: Layout.scanLineHeight)
                        .shadow(color: Palette.scanLineSoft, radius: Layout.scanLineGlowRadius)
                        .shadow(color: Palette.scanLineGlow, radius: Layout.scanLineGlowRadiusOuter)
                        .offset(y: scanLineOffset)

                    // Corner brackets
                    CornerBracketsView(
                        size: Layout.viewfinderSize,
                        cornerLength: Layout.cornerBracketLength,
                        lineWidth: Layout.cornerBracketLineWidth
                    )
                }
                .frame(width: Layout.viewfinderSize, height: Layout.viewfinderSize)
                .clipped()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    vm.updateRegionOfInterest(frame)
                }
                .onAppear {
                    let start = -(Layout.viewfinderSize / 2 - 4)
                    scanLineOffset = start
                    withAnimation(
                        .linear(duration: Motion.scanLineSweep)
                        .repeatForever(autoreverses: false)
                    ) {
                        scanLineOffset = -start
                    }
                }

                Spacer()

                // Cancel button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(Typography.buttonSecondary)
                        .foregroundColor(.white)
                        .padding(.horizontal, Layout.descriptionH)
                        .padding(.vertical, Layout.buttonSpacing)
                        .background(Palette.cancelButton)
                        .cornerRadius(Layout.pillRadius)
                }
                .padding(.bottom, 52)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            vm.onCredentialsFound = onCredentialsFound
            vm.start()
        }
        .onDisappear {
            vm.stop()
        }
    }
}

// MARK: - Corner Brackets

private struct CornerBracketsView: View {
    let size: CGFloat
    let cornerLength: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            corner().offset(x: -size / 2, y: -size / 2)
            corner().rotationEffect(.degrees(90)).offset(x: size / 2, y: -size / 2)
            corner().rotationEffect(.degrees(180)).offset(x: size / 2, y: size / 2)
            corner().rotationEffect(.degrees(270)).offset(x: -size / 2, y: size / 2)
        }
    }

    private func corner() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: cornerLength))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: cornerLength, y: 0))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}
