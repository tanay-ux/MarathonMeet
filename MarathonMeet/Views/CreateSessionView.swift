import SwiftUI

struct CreateSessionView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var notificationService: NotificationService

    @State private var displayName = ""
    @State private var sessionCode: String?
    @State private var errorMessage: String?
    @State private var isCreating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    NeoSectionLabel(text: "Runner", fill: Neo.coral)
                    NeoTextField(label: "Your Name", text: $displayName, placeholder: "Sarah")
                    Text("Spectators will see this name when you're nearby.")
                        .font(.caption.weight(.semibold))
                        .neoSecondaryText()
                }
                .neoStaggeredAppear(index: 0)

                Group {
                    NeoSectionLabel(text: "Course", fill: Neo.mintSoft)
                    HStack {
                        Text("SF Marathon 2026")
                            .font(.headline.weight(.black))
                            .neoPrimaryText()
                        Spacer()
                    }
                    .padding(16)
                    .neoCard(fill: Neo.mintSoft)
                }
                .neoStaggeredAppear(index: 1)

                if let sessionCode {
                    Group {
                        NeoSectionLabel(text: "Session Code", fill: Neo.sun)
                        VStack(spacing: 12) {
                            Text(sessionCode)
                                .font(.system(size: 36, weight: .black, design: .monospaced))
                                .neoPrimaryText()
                                .frame(maxWidth: .infinity)
                            ShareLink(item: "Join my MarathonMeet session with code: \(sessionCode)") {
                                Label("Share Code", systemImage: "square.and.arrow.up")
                                    .font(.headline.weight(.black))
                                    .neoPrimaryText()
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(NeoButtonStyle(fill: Neo.sun))
                        }
                        .padding(20)
                        .neoCard(fill: Neo.paper)
                    }
                    .neoPopIn()
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline.weight(.bold))
                        .neoPrimaryText()
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .neoCard(fill: Neo.pinkSoft)
                        .neoPopIn()
                }

                Group {
                    if sessionCode == nil {
                        Button {
                            Task { await createSession() }
                        } label: {
                            HStack {
                                if isCreating { ProgressView().tint(Neo.ink) }
                                Text("Start Session")
                            }
                        }
                        .buttonStyle(NeoButtonStyle(fill: Neo.coral))
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    } else {
                        Button("Continue to Dashboard") {
                            NeoHaptics.medium()
                            startRunnerTracking()
                        }
                        .buttonStyle(NeoButtonStyle(fill: Neo.limeBright))
                    }
                }
                .neoStaggeredAppear(index: 2)
            }
            .padding(20)
            .animation(NeoMotion.springSmooth, value: sessionCode)
        }
        .neoScreen()
        .neoNavigation()
        .navigationTitle("Start Running")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createSession() async {
        isCreating = true
        errorMessage = nil
        do {
            let code = try await sessionService.createSession(
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
            sessionCode = code
            NeoHaptics.success()
            if let token = notificationService.fcmToken {
                try? await sessionService.updateFCMToken(token)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isCreating = false
    }

    private func startRunnerTracking() {
        locationService.requestAlways()
        locationService.startTracking(forRunner: true) { location in
            Task {
                try? await sessionService.updateLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
        if let threshold = sessionService.currentParticipant?.thresholdMeters {
            WatchConnectivityManager.shared.updateRunnerSession(active: true, threshold: threshold)
        }
    }
}
