import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var lastWatchAlert: ProximityAlert?
    @Published var isSessionActive = false
    @Published var sessionElapsedSeconds: TimeInterval = 0
    @Published var thresholdMeters: Double = 500

    private var sessionStartDate: Date?
    private var elapsedTimer: Timer?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func updateRunnerSession(active: Bool, threshold: Double) {
        isSessionActive = active
        thresholdMeters = threshold
        if active {
            sessionStartDate = Date()
            startElapsedTimer()
        } else {
            sessionStartDate = nil
            elapsedTimer?.invalidate()
            sessionElapsedSeconds = 0
        }
        sendSessionState()
    }

    func sendProximityAlert(_ alert: ProximityAlert) {
        lastWatchAlert = alert
        sendMessage([
            "type": "proximityAlert",
            "personName": alert.personName,
            "distanceMeters": alert.distanceMeters,
            "receivedAt": alert.receivedAt.timeIntervalSince1970
        ])
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            DispatchQueue.main.async {
                self.sessionElapsedSeconds = Date().timeIntervalSince(start)
            }
            self.sendSessionState()
        }
    }

    private func sendSessionState() {
        sendMessage([
            "type": "sessionState",
            "isActive": isSessionActive,
            "thresholdMeters": thresholdMeters,
            "elapsedSeconds": sessionElapsedSeconds,
            "lastAlertName": lastWatchAlert?.personName ?? "",
            "lastAlertDistance": lastWatchAlert?.distanceMeters ?? 0
        ])
    }

    private func sendMessage(_ payload: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("WatchConnectivity error: \(error.localizedDescription)")
            }
        } else {
            try? WCSession.default.updateApplicationContext(payload)
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
