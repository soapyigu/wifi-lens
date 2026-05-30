import UIKit

enum ScanningStatus {
    case looking
    case sawSSID
    case sawPassword
    /// Both fuzzy partials seen but parse() hasn't extracted a validated
    /// pair yet. Diagnostic state — if the UI sits here, the parser is
    /// failing on the label.
    case sawBoth
    /// parse() has succeeded at least once; auto-advance is one stable
    /// frame away.
    case confirmed
}

@MainActor
@Observable
final class ScanningViewModel {
    private let scanner: LiveCredentialScanner

    var partialSSID: String? { scanner.partialSSID }
    var partialPassword: String? { scanner.partialPassword }

    var status: ScanningStatus {
        if scanner.hasParsedOnce { return .confirmed }
        switch (scanner.hasEverSeenSSID, scanner.hasEverSeenPassword) {
        case (false, false): return .looking
        case (true,  false): return .sawSSID
        case (false, true):  return .sawPassword
        case (true,  true):  return .sawBoth
        }
    }

    var onCredentialsFound: ((String, String, UIImage?) -> Void)?

    var scannerController: UIViewController { scanner.viewController }

    init(scanner: LiveCredentialScanner) {
        self.scanner = scanner
        self.scanner.onCredentialsDetected = { [weak self] credentials, snapshot in
            self?.onCredentialsFound?(credentials.ssid, credentials.password, snapshot)
        }
    }

    func start() {
        scanner.start()
    }

    func stop() {
        scanner.stop()
    }

    func updateRegionOfInterest(_ rect: CGRect) {
        scanner.updateRegionOfInterest(rect)
    }
}
