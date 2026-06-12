import Foundation

/// Owns the connect-attempt async work for `ConnectingView`. Emits the
/// outcome through `onSuccess` / `onFailure` so the coordinator can transition
/// to the success or failure screen.
@MainActor
@Observable
final class ConnectingViewModel {
    let credentials: Credentials

    var onSuccess: ((String) -> Void)?
    var onFailure: ((String, String) -> Void)?

    private let connectUseCase: ConnectToWiFiUseCase
    private var connectTask: Task<Void, Never>?

    init(credentials: Credentials, connectUseCase: ConnectToWiFiUseCase) {
        self.credentials = credentials
        self.connectUseCase = connectUseCase
    }

    func connect() {
        connectTask?.cancel()
        connectTask = Task { [weak self] in
            guard let self else { return }
            let success = await connectUseCase.execute(credentials)
            guard !Task.isCancelled else { return }
            if success {
                onSuccess?(credentials.ssid)
            } else {
                onFailure?(credentials.ssid, credentials.password)
            }
        }
    }

    func cancel() {
        connectTask?.cancel()
    }
}
