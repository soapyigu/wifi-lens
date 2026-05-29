import UIKit

@MainActor
@Observable
final class ScanningViewModel {
    private let scanner: LiveCredentialScanner

    var partialSSID: String? { scanner.partialSSID }
    var partialPassword: String? { scanner.partialPassword }

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
