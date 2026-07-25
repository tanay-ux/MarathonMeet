import SwiftUI

struct RunnerDashboardView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var locationService: LocationService
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Neo.spaceLG) {
                    statusCard
                        .neoStaggeredAppear(index: 0)

                    if let alert = sessionService.latestProximityAlert {
                        NeoAlertBanner(
                            title: "\(alert.personName) is nearby!",
                            subtitle: "About \(Int(alert.distanceMeters)) m away"
                        )
                        .neoPopIn()
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }

                    sessionInfoCard
                        .neoStaggeredAppear(index: 1)
                    locationCard
                        .neoStaggeredAppear(index: 2)
                    thresholdCard
                        .neoStaggeredAppear(index: 3)
                }
                .padding(Neo.spaceLG)
                .animation(NeoMotion.springSmooth, value: sessionService.latestProximityAlert?.personName)
            }
            .neoScreen()
            .neoNavigation()
            .navigationTitle("Running")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings") { showSettings = true }
                        .font(.subheadline.weight(.black))
                        .neoPrimaryText()
                        .buttonStyle(NeoToolbarPressStyle())
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sensoryFeedback(.selection, trigger: showSettings) { _, isPresented in
                isPresented
            }
            .onAppear { ensureTracking() }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 14) {
            NeoIconBadge(fill: Neo.limeBright) {
                Image(systemName: "location.fill")
                    .font(.title2.weight(.black))
                    .neoPrimaryText()
            }
            Text("SHARING LOCATION")
                .font(.title2.weight(.black))
                .neoPrimaryText()
            Text("Spectators can see you on the map. You'll get a Watch alert when someone is within your set distance.")
                .font(.subheadline.weight(.semibold))
                .neoSecondaryText()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Neo.spaceXL)
        .neoCard(fill: Neo.paper)
    }

    private var sessionInfoCard: some View {
        VStack(alignment: .leading, spacing: Neo.spaceMD) {
            NeoSectionLabel(text: "Session Code", fill: Neo.sun)

            if let code = sessionService.currentSession?.code {
                Text(code)
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .neoPrimaryText()

                ShareLink(item: "Join my MarathonMeet session: \(code)") {
                    Label("Share with spectators", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.black))
                        .neoPrimaryText()
                }
                .buttonStyle(NeoButtonStyle(fill: Neo.sun, isCompact: false))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Neo.spaceLG)
        .neoCard(fill: Neo.paper)
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            NeoSectionLabel(text: "GPS", fill: Neo.mintSoft)

            if let location = locationService.currentLocation {
                Text(String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude))
                    .font(.caption.weight(.bold).monospaced())
                    .neoSecondaryText()
            } else {
                Text("Waiting for GPS…")
                    .font(.subheadline.weight(.semibold))
                    .neoSecondaryText()
            }

            if !locationService.isAuthorizedForBackground {
                Text("Enable \"Always\" location for reliable tracking during the race.")
                    .font(.caption.weight(.bold))
                    .neoPrimaryText()
                    .padding(10)
                    .neoCard(fill: Neo.pinkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Neo.spaceLG)
        .neoCard(fill: Neo.paper)
    }

    private var thresholdCard: some View {
        VStack(alignment: .leading, spacing: Neo.spaceMD) {
            NeoSectionLabel(text: "Alert Distance", fill: Neo.coral)

            Text("Notify me when a spectator is within:")
                .font(.subheadline.weight(.semibold))
                .neoSecondaryText()

            ThresholdSlider(
                value: Binding(
                    get: { sessionService.currentParticipant?.thresholdMeters ?? 500 },
                    set: { newValue in
                        Task { try? await sessionService.updateThreshold(newValue) }
                        WatchConnectivityManager.shared.updateRunnerSession(active: true, threshold: newValue)
                    }
                ),
                accent: Neo.coral
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Neo.spaceLG)
        .neoCard(fill: Neo.paper)
    }

    private func ensureTracking() {
        guard locationService.currentLocation == nil else { return }
        locationService.requestAlways()
        locationService.startTracking(forRunner: true) { location in
            Task {
                try? await sessionService.updateLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }
}
