import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct MarathonMeetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionService = SessionService()
    @StateObject private var locationService = LocationService()
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionService)
                .environmentObject(locationService)
                .environmentObject(notificationService)
                .onChange(of: notificationService.fcmToken) { _, token in
                    if let token {
                        Task { try? await sessionService.updateFCMToken(token) }
                    }
                }
                .preferredColorScheme(.light)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        NotificationService.shared.configure()
        _ = WatchConnectivityManager.shared
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error.localizedDescription)")
    }
}
