import SwiftUI

struct RunnerWatchView: View {
    @EnvironmentObject var watchState: WatchSessionState

    var body: some View {
        Group {
            if watchState.showAlert {
                alertView
            } else if watchState.isSessionActive {
                activeSessionView
            } else {
                idleView
            }
        }
        .padding(8)
    }

    private var idleView: some View {
        VStack(spacing: 10) {
            watchBadge(icon: "figure.run", fill: Color(red: 1.0, green: 0.42, blue: 0.38))
            Text("MarathonMeet")
                .font(.headline.weight(.black))
            Text("Start on iPhone")
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
    }

    private var activeSessionView: some View {
        VStack(spacing: 10) {
            watchBadge(icon: "location.fill", fill: Color(red: 0.78, green: 0.98, blue: 0.21))
            Text("TRACKING")
                .font(.caption.weight(.black))
            Text(watchState.elapsedFormatted)
                .font(.title3.weight(.black).monospacedDigit())
            Text("\(Int(watchState.thresholdMeters))m alert")
                .font(.caption2.weight(.bold))
        }
    }

    private var alertView: some View {
        VStack(spacing: 8) {
            watchBadge(icon: "bell.fill", fill: Color(red: 1.0, green: 0.45, blue: 0.72))
            Text(watchState.lastAlertName)
                .font(.headline.weight(.black))
                .multilineTextAlignment(.center)
            Text("NEARBY!")
                .font(.caption.weight(.black))
            Text("~\(Int(watchState.lastAlertDistance))m")
                .font(.caption2.weight(.bold))
        }
    }

    private func watchBadge(icon: String, fill: Color) -> some View {
        Image(systemName: icon)
            .font(.title3.weight(.black))
            .foregroundStyle(.black)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.black)
                    .offset(x: 3, y: 3)
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(fill)
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2))
    }
}

#Preview {
    RunnerWatchView()
        .environmentObject(WatchSessionState())
}
