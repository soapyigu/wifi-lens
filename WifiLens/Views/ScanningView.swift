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
    var onCredentialsFound: (String, String, UIImage?) -> Void

    @State private var vm: ScanningViewModel
    @State private var scanLineOffset: CGFloat = 0

    init(onCancel: @escaping () -> Void,
         onCredentialsFound: @escaping (String, String, UIImage?) -> Void) {
        _vm = State(initialValue: ScanningViewModel(
            scanner: LiveCredentialScanner(parser: LiveCredentialParser())
        ))
        self.onCancel = onCancel
        self.onCredentialsFound = onCredentialsFound
    }

    private let viewfinderSize: CGFloat = 260
    private let cornerLength: CGFloat = 28
    private let cornerLineWidth: CGFloat = 4

    private var scanningStatusText: String {
        switch (vm.partialSSID, vm.partialPassword) {
        case (nil, nil):
            return "Looking for Wi-Fi name\nand password..."
        case (.some, nil):
            return "Found network name —\nlooking for password..."
        case (nil, .some):
            return "Found password —\nlooking for network name..."
        default:
            return "Found Wi-Fi details!"
        }
    }

    var body: some View {
        ZStack {
            // Camera feed (hosted by the scanner service via VM)
            DataScannerView(controller: vm.scannerController)
                .ignoresSafeArea()

            // Dark overlay outside the viewfinder cutout
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .mask(
                    Rectangle()
                        .ignoresSafeArea()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .frame(width: viewfinderSize, height: viewfinderSize)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                )

            VStack(spacing: 0) {
                // Status label
                Text(scanningStatusText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: scanningStatusText)
                    .padding(.top, 72)
                    .padding(.horizontal, 32)

                Spacer()

                // Viewfinder with corners and scan line
                ZStack {
                    // Animated scan line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .cyan.opacity(0.9), .cyan, .cyan.opacity(0.9), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: viewfinderSize - 8, height: 3)
                        .shadow(color: .cyan.opacity(0.9), radius: 6)
                        .shadow(color: .cyan.opacity(0.5), radius: 12)
                        .offset(y: scanLineOffset)

                    // Corner brackets
                    CornerBracketsView(
                        size: viewfinderSize,
                        cornerLength: cornerLength,
                        lineWidth: cornerLineWidth
                    )
                }
                .frame(width: viewfinderSize, height: viewfinderSize)
                .clipped()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    vm.updateRegionOfInterest(frame)
                }
                .onAppear {
                    let start = -(viewfinderSize / 2 - 4)
                    scanLineOffset = start
                    withAnimation(
                        .linear(duration: 1.8)
                        .repeatForever(autoreverses: false)
                    ) {
                        scanLineOffset = -start
                    }
                }

                Spacer()

                // Cancel button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(22)
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

#Preview {
    ScanningView(onCancel: {}, onCredentialsFound: { _, _, _ in })
}
