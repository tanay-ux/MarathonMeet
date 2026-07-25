import Foundation

/// Persists a random device ID locally — no accounts or sign-in required.
enum LocalParticipantStore {
    private static let participantIDKey = "marathonmeet.participantID"

    static var participantID: String {
        if let existing = UserDefaults.standard.string(forKey: participantIDKey), !existing.isEmpty {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: participantIDKey)
        return newID
    }
}
