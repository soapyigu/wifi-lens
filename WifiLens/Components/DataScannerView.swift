//
//  DataScannerView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI
import VisionKit
import UIKit

// MARK: - DataScannerModel

@Observable
final class DataScannerModel {
    var partialSSID: String?
    var partialPassword: String?
    var cameraSnapshot: UIImage?

    /// Set by ScanningView before scanning starts. Called once when credentials
    /// are confirmed; cleared immediately to prevent double-firing.
    var onCredentialsDetected: ((String, String, UIImage?) -> Void)?

    weak var scannerVC: DataScannerViewController?

    func startScanning() {
        guard let vc = scannerVC else { return }
        try? vc.startScanning()
    }

    func stopScanning() {
        scannerVC?.stopScanning()
    }

    func updateRegionOfInterest(_ rect: CGRect) {
        scannerVC?.regionOfInterest = rect
    }
}

// MARK: - DataScannerView

struct DataScannerView: UIViewControllerRepresentable {
    var model: DataScannerModel

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isGuidanceEnabled: false, isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        context.coordinator.model.scannerVC = scanner
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }
}

// MARK: - Coordinator

extension DataScannerView {
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var model: DataScannerModel
        private var debounceTask: Task<Void, Never>?

        // Stability: require the same parse result twice before firing the callback.
        private var candidateCredentials: (ssid: String, password: String)?
        private var candidateConfirmCount = 0

        init(model: DataScannerModel) {
            self.model = model
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            handleItems(allItems, scanner: dataScanner)
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            handleItems(allItems, scanner: dataScanner)
        }

        private func handleItems(_ items: [RecognizedItem], scanner: DataScannerViewController) {
            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                // Callback is cleared after first delivery — skip if already fired.
                guard self.model.onCredentialsDetected != nil else { return }

                // Sort top-to-bottom so the parser sees lines in reading order.
                let sortedItems = items.sorted {
                    guard case .text(let a) = $0, case .text(let b) = $1 else { return false }
                    return a.bounds.topLeft.y < b.bounds.topLeft.y
                }
                let transcripts: [String] = sortedItems.compactMap {
                    if case .text(let t) = $0 { return t.transcript } else { return nil }
                }

                let partial = WiFiCredentialParser.partialMatch(transcripts)
                self.model.partialSSID = partial.ssid
                self.model.partialPassword = partial.password

                if let credentials = WiFiCredentialParser.parse(transcripts) {
                    if credentials.ssid == self.candidateCredentials?.ssid &&
                       credentials.password == self.candidateCredentials?.password {
                        self.candidateConfirmCount += 1
                    } else {
                        // New result — start fresh.
                        self.candidateCredentials = credentials
                        self.candidateConfirmCount = 1
                    }

                    if self.candidateConfirmCount >= 2 {
                        let snapshot = self.captureSnapshot(from: scanner)
                        self.model.cameraSnapshot = snapshot
                        // Capture and clear the callback atomically to prevent double-firing.
                        let callback = self.model.onCredentialsDetected
                        self.model.onCredentialsDetected = nil
                        callback?(credentials.ssid, credentials.password, snapshot)
                    }
                } else {
                    // OCR lost the text — reset stability counter.
                    self.candidateCredentials = nil
                    self.candidateConfirmCount = 0
                }
            }
        }

        private func captureSnapshot(from scanner: DataScannerViewController) -> UIImage? {
            guard let view = scanner.view else { return nil }
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            return renderer.image { ctx in
                view.layer.render(in: ctx.cgContext)
            }
        }
    }
}
