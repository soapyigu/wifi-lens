//
//  DataScannerView.swift
//  WifiLens
//
//  Created by Yi Gu on 2/19/26.
//

import SwiftUI
import AVFoundation
import Vision
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

    weak var scannerVC: VisionScannerViewController?

    func startScanning() {
        scannerVC?.startSession()
    }

    func stopScanning() {
        scannerVC?.stopSession()
    }

    func updateRegionOfInterest(_ rect: CGRect) {
        scannerVC?.setRegionOfInterest(rect)
    }
}

// MARK: - VisionScannerViewController

final class VisionScannerViewController: UIViewController,
                                          AVCaptureVideoDataOutputSampleBufferDelegate {
    var onObservations: (([VNRecognizedTextObservation]) -> Void)?

    private let session      = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutput  = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.wifilens.session")
    private let visionQueue  = DispatchQueue(label: "com.wifilens.vision")
    private var frameCounter = 0
    private let frameSkip    = 5           // ~6 recognitions/sec from 30fps

    // Both read and written only on sessionQueue — no data race
    private var cachedVisionROI: CGRect?
    // Written and read only on main thread
    private var pendingScreenROI: CGRect?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupPreviewLayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // FIX 4: guard against force-unwrap crash when called before viewDidLoad
        guard previewLayer != nil else { return }
        previewLayer.frame = view.bounds
        if let pending = pendingScreenROI {
            pendingScreenROI = nil
            setRegionOfInterest(pending)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    // MARK: - Setup

    private func setupCaptureSession() {
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        // FIX 3: use videoRotationAngle instead of deprecated videoOrientation
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
    }

    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }

    // MARK: - Session control

    func startSession() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            sessionQueue.async { self.session.startRunning() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.sessionQueue.async { self.session.startRunning() }
                }
            }
        default:
            break
        }
    }

    func stopSession() {
        sessionQueue.async { self.session.stopRunning() }
    }

    // MARK: - Region of interest

    func setRegionOfInterest(_ screenRect: CGRect) {
        guard previewLayer != nil, previewLayer.bounds != .zero else {
            pendingScreenROI = screenRect
            return
        }
        let layerRect = previewLayer.convert(screenRect, from: nil)
        let meta = previewLayer.metadataOutputRectConverted(fromLayerRect: layerRect)
        // Flip Y (meta is top-left origin, Vision is bottom-left), then clamp to [0,1]
        let newROI = CGRect(
            x: max(0, meta.minX),
            y: max(0, 1 - meta.maxY),
            width:  min(1, meta.width),
            height: min(1, meta.height)
        ).intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        // FIX 2: write on sessionQueue so captureOutput reads on the same queue — no data race
        sessionQueue.async { self.cachedVisionROI = newROI.isEmpty ? nil : newROI }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        frameCounter += 1
        guard frameCounter % frameSkip == 0 else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let roi = cachedVisionROI   // safe: read on sessionQueue, same queue as write

        visionQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                orientation: .right,
                                                options: [:])
            let req = VNRecognizeTextRequest()
            req.recognitionLevel = .accurate
            req.usesLanguageCorrection = false
            req.minimumTextHeight = 0.02
            req.recognitionLanguages = ["zh-Hans", "zh-Hant", "ja", "ko", "en-US"]
            // FIX 1: validate all coordinates before setting — invalid rects cause NSException
            // which try? does NOT catch, crashing the app
            if let roi,
               roi.minX >= 0, roi.minY >= 0,
               roi.maxX <= 1, roi.maxY <= 1,
               roi.width > 0, roi.height > 0 {
                req.regionOfInterest = roi
            }
            try? handler.perform([req])

            let results = (req.results ?? [])
                .filter { $0.topCandidates(1).first?.confidence ?? 0 >= 0.5 }
                .sorted { $0.boundingBox.minY > $1.boundingBox.minY }  // top-to-bottom

            // FIX 5: [weak self] prevents retain cycle when VC is dismissed mid-flight
            DispatchQueue.main.async { [weak self] in self?.onObservations?(results) }
        }
    }
}

// MARK: - DataScannerView

struct DataScannerView: UIViewControllerRepresentable {
    var model: DataScannerModel

    func makeUIViewController(context: Context) -> VisionScannerViewController {
        let vc = VisionScannerViewController()
        let coordinator = context.coordinator
        vc.onObservations = { [weak coordinator] obs in
            coordinator?.handleObservations(obs, scanner: vc)
        }
        context.coordinator.model.scannerVC = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: VisionScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }
}

// MARK: - Coordinator

extension DataScannerView {
    final class Coordinator: NSObject {
        var model: DataScannerModel

        // Stability: require the same parse result twice before firing the callback.
        private var candidateCredentials: (ssid: String, password: String)?
        private var candidateConfirmCount = 0

        init(model: DataScannerModel) {
            self.model = model
        }

        func handleObservations(_ observations: [VNRecognizedTextObservation],
                                scanner: VisionScannerViewController) {
            // No debounce needed: each Vision request returns the complete text set for
            // that frame in one shot (not incremental). Processing synchronously on the
            // main thread is safe — onObservations is already dispatched to main.
            guard model.onCredentialsDetected != nil else { return }

            // Observations arrive pre-sorted top-to-bottom, pre-filtered by confidence
            let transcripts = observations.compactMap { $0.topCandidates(1).first?.string }

            let partial = WiFiCredentialParser.partialMatch(transcripts)
            model.partialSSID    = partial.ssid
            model.partialPassword = partial.password

            if let credentials = WiFiCredentialParser.parse(transcripts) {
                if credentials.ssid == candidateCredentials?.ssid &&
                   credentials.password == candidateCredentials?.password {
                    candidateConfirmCount += 1
                } else {
                    // New result — start fresh.
                    candidateCredentials = credentials
                    candidateConfirmCount = 1
                }

                if candidateConfirmCount >= 2 {
                    let snapshot = captureSnapshot(from: scanner)
                    model.cameraSnapshot = snapshot
                    // Capture and clear the callback atomically to prevent double-firing.
                    let callback = model.onCredentialsDetected
                    model.onCredentialsDetected = nil
                    // Stop the camera immediately — don't wait for onDisappear.
                    scanner.stopSession()
                    callback?(credentials.ssid, credentials.password, snapshot)
                }
            } else {
                // OCR lost the text — reset stability counter.
                candidateCredentials = nil
                candidateConfirmCount = 0
            }
        }

        private func captureSnapshot(from scanner: VisionScannerViewController) -> UIImage? {
            guard let view = scanner.view else { return nil }
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            return renderer.image { ctx in
                view.layer.render(in: ctx.cgContext)
            }
        }
    }
}
