import SwiftUI
import MapKit

struct SpectatorMapView: View {
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var locationService: LocationService

    @State private var courseRoute = GPXParser.loadBundled(named: "SF_Marathon_2026") ?? .empty
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showSettings = false
    @State private var showImporter = false
    @State private var isSheetExpanded = false

    private let collapsedSheetHeight: CGFloat = 118
    private let expandedSheetHeight: CGFloat = 420

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    mapLayer(bottomInset: collapsedSheetHeight + Neo.spaceMD)

                    VStack(spacing: Neo.spaceSM) {
                        if let alert = sessionService.latestProximityAlert {
                            NeoAlertBanner(
                                title: "\(alert.personName) is nearby!",
                                subtitle: "About \(Int(alert.distanceMeters)) m away"
                            )
                            .padding(.horizontal, Neo.spaceMD)
                            .neoPopIn()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Spacer(minLength: 0)

                        NeoDraggableBottomSheet(
                            isExpanded: $isSheetExpanded,
                            collapsedHeight: collapsedSheetHeight,
                            expandedHeight: min(expandedSheetHeight, geo.size.height * 0.58),
                            collapsed: { collapsedSheetContent },
                            expanded: { expandedSheetContent }
                        )
                        .padding(.horizontal, Neo.spaceMD)
                        .padding(.bottom, Neo.spaceSM)
                    }
                    .animation(NeoMotion.springSmooth, value: sessionService.latestProximityAlert?.personName)
                    .animation(NeoMotion.springSmooth, value: isSheetExpanded)
                }
            }
            .neoNavigation()
            .navigationTitle(sessionService.currentSession?.courseName ?? "Spectating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showImporter = true } label: {
                        Image(systemName: "map")
                            .font(.headline.weight(.black))
                    }
                    .buttonStyle(NeoToolbarPressStyle())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings") { showSettings = true }
                        .font(.subheadline.weight(.black))
                        .buttonStyle(NeoToolbarPressStyle())
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sensoryFeedback(.selection, trigger: isSheetExpanded) { _, expanded in
                expanded
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.xml, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    loadGPX(from: url)
                }
            }
            .onAppear {
                locationService.requestWhenInUse()
                startSpectatorTracking()
                recenterMap()
            }
            .onChange(of: sessionService.participants.count) { _, _ in
                recenterMap()
            }
        }
    }

    // MARK: - Map

    private func mapLayer(bottomInset: CGFloat) -> some View {
        Map(position: $cameraPosition) {
            if !courseRoute.coordinates.isEmpty {
                MapPolyline(coordinates: courseRoute.coordinates)
                    .stroke(Neo.electricBright, lineWidth: 4)
            }

            if let runner = sessionService.runner, let coord = runner.coordinate {
                Annotation(runner.displayName, coordinate: coord) {
                    RunnerMapMarker()
                }
            }

            ForEach(sessionService.spectators) { spectator in
                if let coord = spectator.coordinate {
                    Annotation(spectator.displayName, coordinate: coord) {
                        SpectatorMapMarker(isMe: spectator.uid == sessionService.currentParticipant?.uid)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .safeAreaPadding(.bottom, bottomInset)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Bottom sheet (collapsed)

    @ViewBuilder
    private var collapsedSheetContent: some View {
        if let snapshot = trackingSnapshot {
            HStack(alignment: .center, spacing: Neo.spaceMD) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.runnerName)
                        .font(.headline.weight(.black))
                        .neoPrimaryText()

                    Text("to your location")
                        .font(.caption.weight(.semibold))
                        .neoSecondaryText()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let eta = snapshot.etaText {
                        Text(eta)
                            .font(.title2.weight(.black))
                            .neoPrimaryText()
                        Text("ETA")
                            .font(.caption2.weight(.bold))
                            .neoSecondaryText()
                    } else {
                        Text("—")
                            .font(.title2.weight(.black))
                            .neoSecondaryText()
                    }
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text(snapshot.distanceText)
                        .font(.headline.weight(.black))
                        .neoPrimaryText()
                    Text("away")
                        .font(.caption2.weight(.bold))
                        .neoSecondaryText()
                }

                Image(systemName: "chevron.up")
                    .font(.caption.weight(.black))
                    .neoPrimaryText()
                    .padding(.leading, 4)
            }
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Waiting for runner…")
                        .font(.headline.weight(.black))
                        .neoPrimaryText()
                    Text("GPS will update on the map")
                        .font(.caption.weight(.semibold))
                        .neoSecondaryText()
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.black))
                    .neoPrimaryText()
            }
        }
    }

    // MARK: - Bottom sheet (expanded)

    private var expandedSheetContent: some View {
        VStack(alignment: .leading, spacing: Neo.spaceLG) {
            distanceAndETASection

            NeoDivider()

            ThresholdSlider(
                value: Binding(
                    get: { sessionService.currentParticipant?.thresholdMeters ?? 200 },
                    set: { newValue in
                        Task { try? await sessionService.updateThreshold(newValue) }
                    }
                ),
                accent: Neo.electricBright,
                showSectionLabel: true,
                sectionLabel: "Alert Distance"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var distanceAndETASection: some View {
        VStack(alignment: .leading, spacing: Neo.spaceMD) {
            NeoSectionLabel(text: "Distance", fill: Neo.electricBright)

            if let snapshot = trackingSnapshot {
                VStack(alignment: .leading, spacing: Neo.spaceSM) {
                    Text("Runner to you")
                        .font(.subheadline.weight(.semibold))
                        .neoSecondaryText()

                    Text(snapshot.distanceText)
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .neoPrimaryText()
                }
                .padding(.top, Neo.spaceXS)

                if let eta = snapshot.etaText {
                    VStack(alignment: .leading, spacing: Neo.spaceSM) {
                        Text("Estimated arrival at your spot")
                            .font(.subheadline.weight(.semibold))
                            .neoSecondaryText()

                        Text(eta)
                            .font(.title2.weight(.black))
                            .neoPrimaryText()
                            .padding(.horizontal, Neo.spaceMD)
                            .padding(.vertical, Neo.spaceSM)
                            .neoCard(fill: Neo.sun)
                    }
                    .padding(.top, Neo.spaceXS)
                }

                if let updated = snapshot.lastUpdated {
                    Text("Runner location updated \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption.weight(.semibold))
                        .neoSecondaryText()
                        .padding(.top, Neo.spaceXS)
                }
            } else {
                Text("Waiting for runner location…")
                    .font(.subheadline.weight(.semibold))
                    .neoSecondaryText()
                    .padding(.top, Neo.spaceSM)
            }
        }
    }

    // MARK: - Tracking snapshot

    private var trackingSnapshot: SpectatorTrackingSnapshot? {
        guard
            let runner = sessionService.runner,
            let runnerCoord = runner.coordinate,
            let myCoord = sessionService.currentParticipant?.coordinate ?? locationService.currentLocation?.coordinate
        else { return nil }

        let distance = LocationService.distanceMeters(from: runnerCoord, to: myCoord)
        let etaSeconds = LocationService.estimatedArrivalSeconds(
            distanceMeters: distance,
            recentSamples: locationService.recentSamples
        )

        return SpectatorTrackingSnapshot(
            runnerName: runner.displayName,
            distanceMeters: distance,
            etaSeconds: etaSeconds,
            lastUpdated: runner.locationUpdatedAt
        )
    }

    // MARK: - Helpers

    private func startSpectatorTracking() {
        locationService.startTracking(forRunner: false, uploadInterval: 30) { location in
            Task {
                try? await sessionService.updateLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }

    private func recenterMap() {
        var coords: [CLLocationCoordinate2D] = courseRoute.coordinates
        if let runner = sessionService.runner?.coordinate { coords.append(runner) }
        if let me = sessionService.currentParticipant?.coordinate { coords.append(me) }
        guard !coords.isEmpty else { return }

        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.4, 0.02),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.4, 0.02)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func loadGPX(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let route = try? GPXParser.parse(url: url) {
            courseRoute = route
            recenterMap()
        }
    }
}

private struct SpectatorTrackingSnapshot {
    let runnerName: String
    let distanceMeters: Double
    let etaSeconds: TimeInterval?
    let lastUpdated: Date?

    var distanceText: String {
        if distanceMeters >= 1000 {
            return String(format: "%.1f km", distanceMeters / 1000)
        }
        return "\(Int(distanceMeters)) m"
    }

    var etaText: String? {
        guard let etaSeconds else { return nil }
        let minutes = Int(etaSeconds / 60)
        if minutes < 1 { return "~< 1 min" }
        if minutes < 60 { return "~\(minutes) min" }
        return String(format: "~%dh %dm", minutes / 60, minutes % 60)
    }
}
