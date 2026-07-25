import SwiftUI

// MARK: - App logo (home hero)

struct NeoAppLogoIcon: View {
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Neo.ink.opacity(0.18))
                    .frame(width: 4, height: 10 + CGFloat(index) * 5)
                    .offset(x: -size * 0.34 + CGFloat(index) * 3, y: size * 0.06)
            }

            VStack(spacing: 1) {
                Circle()
                    .fill(Neo.ink)
                    .frame(width: size * 0.2, height: size * 0.2)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Neo.ink)
                    .frame(width: size * 0.24, height: size * 0.3)
                    .rotationEffect(.degrees(-8))

                HStack(spacing: 2) {
                    Capsule()
                        .fill(Neo.ink)
                        .frame(width: 4, height: size * 0.22)
                        .rotationEffect(.degrees(28))
                    Capsule()
                        .fill(Neo.ink)
                        .frame(width: 4, height: size * 0.28)
                        .rotationEffect(.degrees(-32))
                }
                .offset(y: -4)
            }
            .offset(x: size * 0.04, y: -size * 0.02)

            Image(systemName: "location.fill")
                .font(.system(size: size * 0.18, weight: .black))
                .foregroundStyle(Neo.sun)
                .padding(4)
                .background(Circle().fill(Neo.ink))
                .offset(x: size * 0.3, y: -size * 0.28)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Role card icons

struct NeoRunnerRoleIcon: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Neo.limeBright)
                .frame(width: 34, height: 10)
                .overlay(Capsule().stroke(Neo.ink, lineWidth: 2))
                .offset(y: 14)

            Group {
                Capsule()
                    .fill(Neo.ink)
                    .frame(width: 3, height: 11)
                    .offset(x: -16, y: 1)
                Capsule()
                    .fill(Neo.ink)
                    .frame(width: 3, height: 15)
                    .offset(x: -11, y: -1)
                Capsule()
                    .fill(Neo.ink)
                    .frame(width: 3, height: 19)
                    .offset(x: -6, y: -3)
            }

            VStack(spacing: 1) {
                Circle()
                    .fill(Neo.ink)
                    .frame(width: 9, height: 9)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Neo.ink)
                    .frame(width: 11, height: 13)
                    .rotationEffect(.degrees(-10))

                HStack(spacing: 3) {
                    Capsule()
                        .fill(Neo.ink)
                        .frame(width: 3.5, height: 12)
                        .rotationEffect(.degrees(35))
                    Capsule()
                        .fill(Neo.ink)
                        .frame(width: 3.5, height: 15)
                        .rotationEffect(.degrees(-38))
                }
                .offset(x: 1, y: -5)
            }
            .offset(x: 3, y: -3)
        }
        .frame(width: 36, height: 36)
    }
}

struct NeoSpectatorRoleIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Neo.sunBright)
                .frame(width: 14, height: 18)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Neo.ink, lineWidth: 2))
                .offset(x: -10, y: 8)
                .rotationEffect(.degrees(-6))

            HStack(spacing: 5) {
                lens
                RoundedRectangle(cornerRadius: 2)
                    .fill(Neo.ink)
                    .frame(width: 5, height: 4)
                lens
            }

            Image(systemName: "heart.fill")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Neo.pinkSoft)
                .padding(3)
                .background(Circle().fill(Neo.ink))
                .offset(x: 16, y: -14)
        }
        .frame(width: 36, height: 36)
    }

    private var lens: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Neo.electricBright)
                .frame(width: 15, height: 15)
            RoundedRectangle(cornerRadius: 6)
                .stroke(Neo.ink, lineWidth: 2.5)
                .frame(width: 15, height: 15)
            Circle()
                .fill(Neo.paper.opacity(0.55))
                .frame(width: 5, height: 5)
                .offset(x: -2, y: -2)
        }
    }
}

// MARK: - Badge wrapper

struct NeoIconBadge<Icon: View>: View {
    let fill: Color
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        icon()
            .frame(width: 52, height: 52)
            .neoCard(fill: fill)
    }
}
