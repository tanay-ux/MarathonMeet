import Foundation
import CoreLocation

enum ParticipantRole: String, Codable {
    case runner
    case spectator
}

enum ProximityState: String, Codable {
    case inRange = "in_range"
    case outOfRange = "out_of_range"
}

struct Participant: Identifiable, Codable {
    var id: String { uid }
    let uid: String
    var displayName: String
    var role: ParticipantRole
    var thresholdMeters: Double
    var latitude: Double?
    var longitude: Double?
    var locationUpdatedAt: Date?
    var fcmToken: String?
    var proximityState: [String: ProximityState]

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        uid: String,
        displayName: String,
        role: ParticipantRole,
        thresholdMeters: Double = 200,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationUpdatedAt: Date? = nil,
        fcmToken: String? = nil,
        proximityState: [String: ProximityState] = [:]
    ) {
        self.uid = uid
        self.displayName = displayName
        self.role = role
        self.thresholdMeters = thresholdMeters
        self.latitude = latitude
        self.longitude = longitude
        self.locationUpdatedAt = locationUpdatedAt
        self.fcmToken = fcmToken
        self.proximityState = proximityState
    }

    init?(documentID: String, data: [String: Any]) {
        guard
            let displayName = data["displayName"] as? String,
            let roleRaw = data["role"] as? String,
            let role = ParticipantRole(rawValue: roleRaw)
        else { return nil }

        self.uid = documentID
        self.displayName = displayName
        self.role = role
        self.thresholdMeters = data["thresholdMeters"] as? Double ?? 200
        self.fcmToken = data["fcmToken"] as? String

        if let location = data["location"] as? [String: Any],
           let lat = location["latitude"] as? Double,
           let lon = location["longitude"] as? Double {
            self.latitude = lat
            self.longitude = lon
        } else {
            self.latitude = nil
            self.longitude = nil
        }

        if let timestamp = data["locationUpdatedAt"] as? TimestampLike {
            self.locationUpdatedAt = timestamp.dateValue()
        } else {
            self.locationUpdatedAt = nil
        }

        if let stateMap = data["proximityState"] as? [String: String] {
            self.proximityState = stateMap.compactMapValues { ProximityState(rawValue: $0) }
        } else {
            self.proximityState = [:]
        }
    }

    func firestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "displayName": displayName,
            "role": role.rawValue,
            "thresholdMeters": thresholdMeters,
            "proximityState": proximityState.mapValues { $0.rawValue }
        ]
        if let fcmToken { data["fcmToken"] = fcmToken }
        if let latitude, let longitude {
            data["location"] = ["latitude": latitude, "longitude": longitude]
        }
        if let locationUpdatedAt {
            data["locationUpdatedAt"] = locationUpdatedAt
        }
        return data
    }
}

protocol TimestampLike {
    func dateValue() -> Date
}

extension Date: TimestampLike {
    func dateValue() -> Date { self }
}

struct RaceSession: Identifiable {
    var id: String { code }
    let code: String
    var isActive: Bool
    var createdAt: Date
    var courseName: String?

    init(code: String, isActive: Bool = true, createdAt: Date = Date(), courseName: String? = nil) {
        self.code = code
        self.isActive = isActive
        self.createdAt = createdAt
        self.courseName = courseName
    }

    init?(documentID: String, data: [String: Any]) {
        self.code = documentID
        self.isActive = data["isActive"] as? Bool ?? true
        self.courseName = data["courseName"] as? String
        if let timestamp = data["createdAt"] as? TimestampLike {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
    }
}

struct ProximityAlert: Identifiable, Equatable {
    let id = UUID()
    let personName: String
    let distanceMeters: Double
    let receivedAt: Date
}

struct LocationSample {
    let coordinate: CLLocationCoordinate2D
    let speed: CLLocationSpeed
    let timestamp: Date
}
