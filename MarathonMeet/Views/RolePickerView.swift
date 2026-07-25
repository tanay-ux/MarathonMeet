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
                            NeoAppLogoIcon(size: 48)
                        }

                        NeoTitle(text: "MarathonMeet")

                        Text("Know when you're close enough to cheer each other on.")
                            .font(.subheadline.weight(.semibold))
                            .neoSecondaryText()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 32)
                    .neoStaggeredAppear(index: 0)

                    VStack(spacing: 16) {
                        // Buttons + path (not NavigationLink) so system link tint
                        // cannot force card fills to black.
                        Button {
                            path.append(AppRoute.createRunner)
                        } label: {
                            NeoRoleButton(
                                title: "I'm Running",
                                subtitle: "Share your location during the race",
                                fill: Neo.coral
                            ) {
                                NeoRunnerRoleIcon()
                            }
                        }
                        .buttonStyle(NeoCardPressStyle())
                        .neoStaggeredAppear(index: 1)

                        Button {
                            path.append(AppRoute.joinSpectator)
                        } label: {
                            NeoRoleButton(
                                title: "I'm Spectating",
                                subtitle: "Track the runner & get proximity alerts",
                                fill: Neo.electricBright
                            ) {
                                NeoSpectatorRoleIcon()
                            }
                        }
                        .buttonStyle(NeoCardPressStyle())
                        .neoStaggeredAppear(index: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .neoScreen()
            .neoNavigation()
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .createRunner:
                        CreateSessionView()
                    case .joinSpectator:
                        JoinSessionView(role: .spectator)
                    case .joinRunner:
                        JoinSessionView(role: .runner)
                    }
                }
                .neoStaggeredAppear(index: 0, baseDelay: 0.04)
            }
        }
    }
}

enum AppRoute: Hashable {
    case createRunner
    case joinSpectator
    case joinRunner
}
