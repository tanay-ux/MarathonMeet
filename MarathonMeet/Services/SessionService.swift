import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class SessionService: ObservableObject {
    @Published var currentSession: RaceSession?
    @Published var currentParticipant: Participant?
    @Published var participants: [Participant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var latestProximityAlert: ProximityAlert?

    private let db = Firestore.firestore()
    private var participantsListener: ListenerRegistration?
    private let participantID = LocalParticipantStore.participantID
    private var lastLocalAlertKey: String?

    var runner: Participant? {
        participants.first { $0.role == .runner }
    }

    var spectators: [Participant] {
        participants.filter { $0.role == .spectator }
    }

    func createSession(displayName: String, courseName: String = "SF Marathon 2026") async throws -> String {
        isLoading = true
        defer { isLoading = false }

        let code = Self.generateSessionCode()
        let session = RaceSession(code: code, courseName: courseName)
        let participant = Participant(
            uid: participantID,
            displayName: displayName,
            role: .runner,
            thresholdMeters: 500
        )

        try await db.collection("sessions").document(code).setData([
            "isActive": session.isActive,
            "createdAt": FieldValue.serverTimestamp(),
            "courseName": courseName
        ])

        try await saveParticipant(participant, sessionCode: code)
        currentSession = session
        currentParticipant = participant
        listenToParticipants(sessionCode: code)
        return code
    }

    func joinSession(code: String, displayName: String, role: ParticipantRole) async throws {
        isLoading = true
        defer { isLoading = false }

        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let doc = try await db.collection("sessions").document(normalizedCode).getDocument()
        guard doc.exists, let data = doc.data(), data["isActive"] as? Bool != false else {
            throw SessionError.sessionNotFound
        }

        if role == .runner {
            let existing = try await db.collection("sessions").document(normalizedCode)
                .collection("participants")
                .whereField("role", isEqualTo: ParticipantRole.runner.rawValue)
                .getDocuments()
            if !existing.documents.isEmpty {
                throw SessionError.runnerAlreadyExists
            }
        }

        let participant = Participant(
            uid: participantID,
            displayName: displayName,
            role: role,
            thresholdMeters: role == .runner ? 500 : 200
        )

        try await saveParticipant(participant, sessionCode: normalizedCode)
        currentSession = RaceSession(documentID: normalizedCode, data: data)
        currentParticipant = participant
        listenToParticipants(sessionCode: normalizedCode)
    }

    func updateThreshold(_ meters: Double) async throws {
        guard let session = currentSession, let participant = currentParticipant else { return }
        var updated = participant
        updated.thresholdMeters = meters
        try await db.collection("sessions").document(session.code)
            .collection("participants").document(participant.uid)
            .updateData(["thresholdMeters": meters])
        currentParticipant = updated
    }

    func updateLocation(latitude: Double, longitude: Double) async throws {
        guard let session = currentSession, let participant = currentParticipant else { return }
        try await db.collection("sessions").document(session.code)
            .collection("participants").document(participant.uid)
            .updateData([
                "location": ["latitude": latitude, "longitude": longitude],
                "locationUpdatedAt": FieldValue.serverTimestamp()
            ])
    }

    func updateFCMToken(_ token: String) async throws {
        guard let session = currentSession, let participant = currentParticipant else { return }
        try await db.collection("sessions").document(session.code)
            .collection("participants").document(participant.uid)
            .updateData(["fcmToken": token])
        var updated = participant
        updated.fcmToken = token
        currentParticipant = updated
    }

    func endSession() {
        participantsListener?.remove()
        participantsListener = nil
        currentSession = nil
        currentParticipant = nil
        participants = []
    }

    private func saveParticipant(_ participant: Participant, sessionCode: String) async throws {
        try await db.collection("sessions").document(sessionCode)
            .collection("participants").document(participant.uid)
            .setData(participant.firestoreData(), merge: true)
    }

    private func listenToParticipants(sessionCode: String) {
        participantsListener?.remove()
        participantsListener = db.collection("sessions").document(sessionCode)
            .collection("participants")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    Task { @MainActor in self.errorMessage = error.localizedDescription }
                    return
                }
                Task { @MainActor in
                    self.participants = snapshot?.documents.compactMap {
                        Participant(documentID: $0.documentID, data: $0.data())
                    } ?? []
                    self.evaluateLocalProximityAlerts()
                }
            }
    }

    private func evaluateLocalProximityAlerts() {
        guard let me = currentParticipant, let myCoord = me.coordinate else { return }

        let others: [Participant]
        if me.role == .runner {
            others = spectators
        } else if let runner {
            others = [runner]
        } else {
            return
        }

        for other in others {
            guard let otherCoord = other.coordinate else { continue }
            let distance = LocationService.distanceMeters(from: myCoord, to: otherCoord)
            if distance <= me.thresholdMeters {
                let alertKey = "\(other.uid)-in"
                guard lastLocalAlertKey != alertKey else { continue }
                lastLocalAlertKey = alertKey

                let alert = ProximityAlert(
                    personName: other.displayName,
                    distanceMeters: distance,
                    receivedAt: Date()
                )
                latestProximityAlert = alert
                WatchConnectivityManager.shared.sendProximityAlert(alert)
                NotificationService.shared.showLocalProximityAlert(
                    title: "\(other.displayName) is nearby!",
                    body: "About \(Int(distance)) m away — look up!"
                )
            } else if distance > me.thresholdMeters + 50, lastLocalAlertKey == "\(other.uid)-in" {
                lastLocalAlertKey = nil
            }
        }
    }

    private static func generateSessionCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

enum SessionError: LocalizedError {
    case sessionNotFound
    case runnerAlreadyExists

    var errorDescription: String? {
        switch self {
        case .sessionNotFound: return "Session not found. Check the code and try again."
        case .runnerAlreadyExists: return "This session already has a runner."
        }
    }
}

extension Timestamp: TimestampLike {}
