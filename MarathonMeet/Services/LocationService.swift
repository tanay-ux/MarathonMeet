import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var recentSamples: [LocationSample] = []

    private let manager = CLLocationManager()
    private var uploadTimer: Timer?
    private var onLocationUpdate: ((CLLocation) -> Void)?

    var isAuthorizedForBackground: Bool {
        authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking(forRunner: Bool, uploadInterval: TimeInterval = 15, onUpdate: @escaping (CLLocation) -> Void) {
        onLocationUpdate = onUpdate
        manager.allowsBackgroundLocationUpdates = forRunner
        manager.startUpdatingLocation()

        uploadTimer?.invalidate()
        uploadTimer = Timer.scheduledTimer(withTimeInterval: uploadInterval, repeats: true) { [weak self] _ in
            guard let self, let location = self.currentLocation else { return }
            Task { @MainActor in
                self.onLocationUpdate?(location)
            }
        }
    }

    func stopTracking() {
        uploadTimer?.invalidate()
        uploadTimer = nil
        manager.stopUpdatingLocation()
        onLocationUpdate = nil
    }

    private func recordSample(_ location: CLLocation) {
        let sample = LocationSample(
            coordinate: location.coordinate,
            speed: max(location.speed, 0),
            timestamp: location.timestamp
        )
        recentSamples.append(sample)
        if recentSamples.count > 10 {
            recentSamples.removeFirst(recentSamples.count - 10)
        }
    }

    static func distanceMeters(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let a = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let b = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return a.distance(from: b)
    }

    static func estimatedArrivalSeconds(distanceMeters: Double, recentSamples: [LocationSample]) -> TimeInterval? {
        let speeds = recentSamples.map(\.speed).filter { $0 > 0.5 }
        guard !speeds.isEmpty else { return nil }
        let avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
        guard avgSpeed > 0 else { return nil }
        return distanceMeters / avgSpeed
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            recordSample(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
