import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchSessionState: NSObject, ObservableObject {
    @Published var isSessionActive = false
    @Published var thresholdMeters: Double = 500
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var lastAlertName = ""
    @Published var lastAlertDistance: Double = 0
    @Published var showAlert = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    var elapsedFormatted: String {
        let total = Int(elapsedSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension WatchSessionState: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handlePayload(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            handlePayload(applicationContext)
        }
    }

    private func handlePayload(_ payload: [String: Any]) {
        guard let type = payload["type"] as? String else { return }

        switch type {
        case "sessionState":
            isSessionActive = payload["isActive"] as? Bool ?? false
            thresholdMeters = payload["thresholdMeters"] as? Double ?? thresholdMeters
            elapsedSeconds = payload["elapsedSeconds"] as? TimeInterval ?? elapsedSeconds
            if let name = payload["lastAlertName"] as? String, !name.isEmpty {
                lastAlertName = name
                lastAlertDistance = payload["lastAlertDistance"] as? Double ?? 0
            }
        case "proximityAlert":
            lastAlertName = payload["personName"] as? String ?? ""
            lastAlertDistance = payload["distanceMeters"] as? Double ?? 0
            showAlert = true
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                self?.showAlert = false
            }
        default:
            break
        }
    }
}

import WatchKit
