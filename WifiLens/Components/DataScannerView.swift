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
            req.recognitionLanguages = ["en-US"]
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
            // FIX 6: MainActor.assumeIsolated keeps the callback chain synchronous on
            // the main actor. Without it, Swift treats this DispatchQueue.main.async
            // block as nonisolated, inserts an implicit actor hop to reach the
            // @MainActor onObservations property, and SwiftUI @State mutations made
            // downstream don't trigger a re-render (visible only under a debugger
            // pause that flushes the deferred work).
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    self?.onObservations?(results)
                }
            }
        }
    }
}

// MARK: - DataScannerView

struct DataScannerView: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
