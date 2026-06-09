//
//  FoundDetailsView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI
import UIKit
import Combine

struct FoundDetailsView: View {
    var backgroundImage: UIImage?
    var onRescan: () -> Void
    var onConnect: (String, String) -> Void

    @State private var vm: FoundDetailsViewModel
    @FocusState private var focused: Field?
    @State private var keyboardHeight: CGFloat = 0

    private enum Field: Hashable { case ssid, password }

    private static let keyboardHeightPublisher: AnyPublisher<CGFloat, Never> = Publishers.Merge(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height },
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
    )
    .eraseToAnyPublisher()

    init(networkName: String, password: String, backgroundImage: UIImage? = nil,
         onRescan: @escaping () -> Void, onConnect: @escaping (String, String) -> Void) {
        _vm = State(initialValue: FoundDetailsViewModel(ssid: networkName, password: password))
        self.backgroundImage = backgroundImage
        self.onRescan = onRescan
        self.onConnect = onConnect
    }

    var body: some View {
        @Bindable var vm = vm
        return ZStack(alignment: .bottom) {
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
                    TextField("Network Name", text: $vm.networkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.next)
                        .focused($focused, equals: .ssid)
                        .onSubmit { focused = .password }
                }
                .padding(.bottom, 16)

                // Password row
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack {
                        if vm.isPasswordVisible {
                            TextField("Password", text: $vm.password)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.asciiCapable)
                                .submitLabel(.go)
                                .focused($focused, equals: .password)
                                .onSubmit { onConnect(vm.networkName, vm.password) }
                        } else {
                            SecureField("Password", text: $vm.password)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .keyboardType(.asciiCapable)
                                .submitLabel(.go)
                                .focused($focused, equals: .password)
                                .onSubmit { onConnect(vm.networkName, vm.password) }
                        }
                        Spacer()
                        Button(action: { vm.isPasswordVisible.toggle() }) {
                            Image(systemName: vm.isPasswordVisible ? "eye.slash" : "eye")
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

                    Button(action: { onConnect(vm.networkName, vm.password) }) {
                        Text("Connect")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(14)
                    }
                }
                .padding(.bottom, focused == nil ? 48 : 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, keyboardHeight)
            .background(
                Color(.systemBackground)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .ignoresSafeArea(.container, edges: .bottom)
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = nil }
                }
            }
        }
        .ignoresSafeArea()
        .onReceive(Self.keyboardHeightPublisher) { height in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = height
            }
        }
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
