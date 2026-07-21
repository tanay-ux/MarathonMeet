import SwiftUI

struct RolePickerView: View {
    @EnvironmentObject var sessionService: SessionService
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Neo.ink)
                                .frame(width: 96, height: 96)
                                .offset(x: Neo.shadow, y: Neo.shadow)
                            Circle()
                                .fill(Neo.coral)
                                .frame(width: 96, height: 96)
                                .overlay(Circle().stroke(Neo.ink, lineWidth: Neo.border))
                            Image(systemName: "figure.run")
                                .font(.system(size: 40, weight: .black))
                                .foregroundStyle(Neo.ink)
                        }

                        NeoTitle(text: "MarathonMeet")

                        Text("Know when you're close enough to cheer each other on.")
                            .font(.subheadline.weight(.semibold))
                            .neoSecondaryText()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 16) {
                        NavigationLink(value: AppRoute.createRunner) {
                            NeoRoleButton(
                                title: "I'm Running",
                                subtitle: "Share your location during the race",
                                icon: "figure.run",
                                fill: Neo.coral
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: AppRoute.joinSpectator) {
                            NeoRoleButton(
                                title: "I'm Spectating",
                                subtitle: "Track the runner & get proximity alerts",
                                icon: "binoculars.fill",
                                fill: Neo.electricBright
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .neoScreen()
            .neoNavigation()
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .createRunner:
                    CreateSessionView()
                case .joinSpectator:
                    JoinSessionView(role: .spectator)
                case .joinRunner:
                    JoinSessionView(role: .runner)
                }
            }
        }
    }
}

enum AppRoute: Hashable {
    case createRunner
    case joinSpectator
    case joinRunner
}
