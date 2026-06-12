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
    private let scanUseCase: ScanForCredentialsUseCase

    var partialSSID: String? { scanUseCase.partialSSID }
    var partialPassword: String? { scanUseCase.partialPassword }

    var status: ScanningStatus {
        if scanUseCase.hasParsedOnce { return .confirmed }
        switch (scanUseCase.hasEverSeenSSID, scanUseCase.hasEverSeenPassword) {
        case (false, false): return .looking
        case (true,  false): return .sawSSID
        case (false, true):  return .sawPassword
        case (true,  true):  return .sawBoth
        }
    }

    var onCredentialsFound: ((Credentials, UIImage?) -> Void)?

    var cameraScene: UIViewController { scanUseCase.cameraScene }

    init(scanUseCase: ScanForCredentialsUseCase) {
        self.scanUseCase = scanUseCase
        self.scanUseCase.onCredentialsFound = { [weak self] credentials, snapshot in
            self?.onCredentialsFound?(credentials, snapshot)
        }
    }

    func start() {
        scanUseCase.start()
    }

    func stop() {
        scanUseCase.stop()
    }

    func updateRegionOfInterest(_ rect: CGRect) {
        scanUseCase.updateRegionOfInterest(rect)
    }
}
