import UIKit
import Vision

@MainActor
protocol CredentialScanning: AnyObject {
    var partialSSID: String? { get }
    var partialPassword: String? { get }
    var onCredentialsDetected: ((Credentials, UIImage?) -> Void)? { get set }
    func start()
    func stop()
    func updateRegionOfInterest(_ rect: CGRect)
}

@MainActor
@Observable
final class LiveCredentialScanner: CredentialScanning {
    private(set) var partialSSID: String?
    private(set) var partialPassword: String?
    /// Monotonic best-so-far within a session. Reset on start(); never
    /// reverts to false once a candidate is observed. Drives the
    /// scanning-status UI so it doesn't flicker frame-to-frame.
    private(set) var hasEverSeenSSID: Bool = false
    private(set) var hasEverSeenPassword: Bool = false
    /// Set when parse() returns a validated credential pair at least once.
    /// Distinguishes "fuzzy keyword match" from "actually extracted values" —
    /// drives the .confirmed status so the UI doesn't promise an advance the
    /// parser can't deliver.
    private(set) var hasParsedOnce: Bool = false
    var onCredentialsDetected: ((Credentials, UIImage?) -> Void)?

    let viewController: VisionScannerViewController

    private let parser: CredentialParsing
    private var candidate: Credentials?
    private var candidateConfirmCount = 0
    private let stabilityThreshold = 2

    init(parser: CredentialParsing) {
        self.parser = parser
        self.viewController = VisionScannerViewController()
        self.viewController.onObservations = { [weak self] observations in
            self?.handleObservations(observations)
        }
    }

    func start() {
        hasEverSeenSSID = false
        hasEverSeenPassword = false
        hasParsedOnce = false
        viewController.startSession()
    }

    func stop() {
        viewController.stopSession()
    }

    func updateRegionOfInterest(_ rect: CGRect) {
        viewController.setRegionOfInterest(rect)
    }

    private func handleObservations(_ observations: [VNRecognizedTextObservation]) {
        guard onCredentialsDetected != nil else { return }

        let transcripts = observations.compactMap { $0.topCandidates(1).first?.string }

        let partial = parser.partialMatch(transcripts)
        partialSSID = partial.ssid
        partialPassword = partial.password
        if partial.ssid != nil { hasEverSeenSSID = true }
        if partial.password != nil { hasEverSeenPassword = true }

        guard let credentials = parser.parse(transcripts) else {
            candidate = nil
            candidateConfirmCount = 0
            return
        }
        hasParsedOnce = true

        if credentials == candidate {
            candidateConfirmCount += 1
        } else {
            candidate = credentials
            candidateConfirmCount = 1
        }

        guard candidateConfirmCount >= stabilityThreshold else { return }

        let snapshot = captureSnapshot()
        let callback = onCredentialsDetected
        onCredentialsDetected = nil
        viewController.stopSession()
        callback?(credentials, snapshot)
    }

    private func captureSnapshot() -> UIImage? {
        guard let view = viewController.viewIfLoaded else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
    }
}
