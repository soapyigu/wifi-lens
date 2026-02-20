//
//  ScanningView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI
import AVFoundation

struct ScanningView: View {
    var onCancel: () -> Void

    @State private var camera = CameraModel()
    @State private var scanLineOffset: CGFloat = 0

    private let viewfinderSize: CGFloat = 260
    private let cornerLength: CGFloat = 28
    private let cornerLineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Camera feed
            CameraPreviewView(session: camera.session)
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
                // Top label
                Text("Looking for Wi-Fi name\nand password...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 72)
                    .padding(.horizontal, 32)

                Spacer()

                // Viewfinder with corners and scan line
                ZStack {
                    // Animated scan line
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: viewfinderSize - 8, height: 2)
                        .offset(y: scanLineOffset)
                        .clipShape(RoundedRectangle(cornerRadius: 1))

                    // Corner brackets
                    CornerBracketsView(
                        size: viewfinderSize,
                        cornerLength: cornerLength,
                        lineWidth: cornerLineWidth
                    )
                }
                .frame(width: viewfinderSize, height: viewfinderSize)
                .onAppear {
                    let start = -(viewfinderSize / 2 - 4)
                    scanLineOffset = start
                    withAnimation(
                        .easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true)
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
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}

// MARK: - Corner Brackets

private struct CornerBracketsView: View {
    let size: CGFloat
    let cornerLength: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            corner().offset(x: -size / 2, y: -size / 2)                              // top-left
            corner().rotationEffect(.degrees(90)).offset(x: size / 2, y: -size / 2)  // top-right
            corner().rotationEffect(.degrees(180)).offset(x: size / 2, y: size / 2)  // bottom-right
            corner().rotationEffect(.degrees(270)).offset(x: -size / 2, y: size / 2) // bottom-left
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

// MARK: - Camera Model

@Observable
class CameraModel {
    let session = AVCaptureSession()

    init() {
        setup()
    }

    private func setup() {
        session.sessionPreset = .photo
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }
        session.addInput(input)
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
    }
}

#Preview {
    ScanningView(onCancel: {})
}
