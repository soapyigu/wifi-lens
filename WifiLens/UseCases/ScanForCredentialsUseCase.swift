import UIKit

/// Business action: drive the camera/Vision pipeline and surface progress so the
/// VM can render scanning status and accept the resulting credentials.
///
/// Implements the Facade pattern over the scanning subsystem
/// (`CredentialScanning` service, which internally uses a `CredentialParsing`
/// service).
@MainActor
protocol ScanForCredentialsUseCase: AnyObject {
    var partialSSID: String? { get }
    var partialPassword: String? { get }
    var hasEverSeenSSID: Bool { get }
    var hasEverSeenPassword: Bool { get }
    var hasParsedOnce: Bool { get }
    var cameraScene: UIViewController { get }
    var onCredentialsFound: ((Credentials, UIImage?) -> Void)? { get set }

    func start()
    func stop()
    func updateRegionOfInterest(_ rect: CGRect)
}

@MainActor
@Observable
final class LiveScanForCredentialsUseCase: ScanForCredentialsUseCase {
    private let scanner: CredentialScanning

    init(scanner: CredentialScanning) {
        self.scanner = scanner
    }

    var partialSSID: String? { scanner.partialSSID }
    var partialPassword: String? { scanner.partialPassword }
    var hasEverSeenSSID: Bool { scanner.hasEverSeenSSID }
    var hasEverSeenPassword: Bool { scanner.hasEverSeenPassword }
    var hasParsedOnce: Bool { scanner.hasParsedOnce }
    var cameraScene: UIViewController { scanner.viewController }

    var onCredentialsFound: ((Credentials, UIImage?) -> Void)? {
        get { scanner.onCredentialsDetected }
        set { scanner.onCredentialsDetected = newValue }
    }

    func start() { scanner.start() }
    func stop() { scanner.stop() }
    func updateRegionOfInterest(_ rect: CGRect) { scanner.updateRegionOfInterest(rect) }
}
