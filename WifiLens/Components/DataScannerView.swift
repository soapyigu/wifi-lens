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
    var detectedCredentials: (ssid: String, password: String)?
    var cameraSnapshot: UIImage?

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
    @Binding var model: DataScannerModel

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
        Coordinator(model: $model)
    }
}

// MARK: - Coordinator

extension DataScannerView {
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var model: DataScannerModel
        private var debounceTask: Task<Void, Never>?

        init(model: Binding<DataScannerModel>) {
            self._model = model
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
                guard model.detectedCredentials == nil else { return }

                let transcripts: [String] = items.compactMap {
                    if case .text(let t) = $0 { return t.transcript } else { return nil }
                }

                let partial = WiFiCredentialParser.partialMatch(transcripts)
                model.partialSSID = partial.ssid
                model.partialPassword = partial.password

                if let credentials = WiFiCredentialParser.parse(transcripts) {
                    model.cameraSnapshot = captureSnapshot(from: scanner)
                    model.detectedCredentials = credentials
                }
            }
        }

        private func captureSnapshot(from scanner: DataScannerViewController) -> UIImage? {
            guard let view = scanner.view else {
                return nil
            }
            
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            return renderer.image { ctx in
                view.layer.render(in: ctx.cgContext)
            }
        }
    }
}
