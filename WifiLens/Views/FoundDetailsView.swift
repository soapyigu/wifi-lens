//
//  FoundDetailsView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI
import UIKit

struct FoundDetailsView: View {
    var backgroundImage: UIImage?
    var onRescan: () -> Void
    var onConnect: (String, String) -> Void

    @State private var networkName: String
    @State private var password: String
    @State private var isPasswordVisible = false

    init(networkName: String, password: String, backgroundImage: UIImage? = nil,
         onRescan: @escaping () -> Void, onConnect: @escaping (String, String) -> Void) {
        _networkName = State(initialValue: networkName)
        _password = State(initialValue: password)
        self.backgroundImage = backgroundImage
        self.onRescan = onRescan
        self.onConnect = onConnect
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Blurred camera snapshot background
            Group {
                if let image = backgroundImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 8, opaque: true)
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()
            .overlay(Color.green.opacity(0.12).ignoresSafeArea())

            // "Found Wi-Fi details" top label
            VStack {
                Text("Found Wi-Fi details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.top, 72)
                Spacer()
            }

            // Bottom sheet
            VStack(alignment: .leading, spacing: 0) {
                // Handle
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 36, height: 4)
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.bottom, 20)

                // Header
                HStack(spacing: 10) {
                    Text("Detected Wi-Fi")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 20)

                // Network name row
                VStack(alignment: .leading, spacing: 6) {
                    Text("Network Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("Network Name", text: $networkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.bottom, 16)

                // Password row
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Password", text: $password)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 20)

                // Looks good indicator
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 15))
                    Text("Looks good")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.bottom, 24)

                // Buttons
                HStack(spacing: 12) {
                    Button(action: onRescan) {
                        Text("Rescan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0x36/255, green: 0x41/255, blue: 0x53/255, alpha: 1) : UIColor(red: 0xE5/255, green: 0xE7/255, blue: 0xEB/255, alpha: 1) }))
                            .cornerRadius(14)
                    }

                    Button(action: { onConnect(networkName, password) }) {
                        Text("Connect")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(14)
                    }
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
            .background(Color(.systemBackground))
            .cornerRadius(24, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea()
    }
}

// MARK: - Rounded corners helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    FoundDetailsView(
        networkName: "HomeNetwork_5G",
        password: "mypassword123",
        backgroundImage: nil,
        onRescan: {},
        onConnect: { _, _ in }
    )
}
