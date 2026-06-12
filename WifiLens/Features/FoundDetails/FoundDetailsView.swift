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
            .overlay(Palette.successTint.ignoresSafeArea())

            // "Found Wi-Fi details" top label
            VStack {
                Text("Found Wi-Fi details")
                    .font(Typography.statusLabel)
                    .foregroundColor(Palette.success)
                    .padding(.top, Layout.topTitle)
                Spacer()
            }

            // Bottom sheet
            VStack(alignment: .leading, spacing: 0) {
                // Handle
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: Layout.handleRadius)
                        .fill(Palette.handle)
                        .frame(width: Layout.handleWidth, height: Layout.handleHeight)
                    Spacer()
                }
                .padding(.top, Layout.buttonSpacing)
                .padding(.bottom, Layout.sectionGap)

                // Header
                HStack(spacing: 10) {
                    Text("Detected Wi-Fi")
                        .font(Typography.sectionTitle)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, Layout.sectionGap)

                // Network name row
                VStack(alignment: .leading, spacing: 6) {
                    Text("Network Name")
                        .font(Typography.fieldLabel)
                        .foregroundColor(.secondary)
                    TextField("Network Name", text: $vm.networkName)
                        .font(Typography.bodyEmphasis)
                        .foregroundColor(.primary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.next)
                        .focused($focused, equals: .ssid)
                        .onSubmit { focused = .password }
                }
                .padding(.bottom, Layout.rowGap)

                // Password row
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(Typography.fieldLabel)
                        .foregroundColor(.secondary)
                    HStack {
                        if vm.isPasswordVisible {
                            TextField("Password", text: $vm.password)
                                .font(Typography.bodyEmphasis)
                                .foregroundColor(.primary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.asciiCapable)
                                .submitLabel(.go)
                                .focused($focused, equals: .password)
                                .onSubmit { onConnect(vm.networkName, vm.password) }
                        } else {
                            SecureField("Password", text: $vm.password)
                                .font(Typography.bodyEmphasis)
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
                .padding(.bottom, Layout.sectionGap)

                // Looks good indicator
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Palette.success)
                        .font(Typography.inlineIcon)
                    Text("Looks good")
                        .font(Typography.captionEmphasis)
                        .foregroundColor(Palette.success)
                }
                .padding(.bottom, Layout.cardH)

                // Buttons
                HStack(spacing: Layout.buttonSpacing) {
                    Button(action: onRescan) {
                        Text("Rescan")
                            .font(Typography.bodyEmphasis)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.rowGap)
                            .background(Palette.secondaryButton)
                            .cornerRadius(Layout.buttonRadius)
                    }

                    Button(action: { onConnect(vm.networkName, vm.password) }) {
                        Text("Connect")
                            .font(Typography.bodyEmphasis)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.rowGap)
                            .background(Palette.accent)
                            .cornerRadius(Layout.buttonRadius)
                    }
                }
                .padding(.bottom, focused == nil ? Layout.bottomSafe : Layout.rowGap)
            }
            .padding(.horizontal, Layout.cardH)
            .padding(.bottom, keyboardHeight)
            .background(
                Palette.cardFill
                    .cornerRadius(Layout.cardRadius, corners: [.topLeft, .topRight])
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
            withAnimation(.easeOut(duration: Motion.keyboardLift)) {
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
