import SwiftUI
import UIKit

// MARK: - Palette (WCAG AA — 4.5:1 body text on canvas/paper)

enum Neo {
    static let border: CGFloat = 3
    static let shadow: CGFloat = 5
    static let radius: CGFloat = 14

    /// Warm cream — primary screen background
    static let canvas = Color(red: 1.0, green: 0.96, blue: 0.82)
    static let ink = Color.black
    static let paper = Color.white

    /// Fixed secondary/tertiary grays — do not use `.opacity()` on ink for body copy
    static let inkSecondary = Color(red: 0.24, green: 0.24, blue: 0.24)   // ≥4.5:1 on canvas & paper
    static let inkTertiary = Color(red: 0.38, green: 0.38, blue: 0.38)    // ≥4.5:1 on paper; large text on canvas

    /// Accent fills — always pair with `Neo.ink` for text/icons on top
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.38)
    static let electric = Color(red: 0.12, green: 0.35, blue: 0.78)       // darkened for contrast with white if needed
    static let electricBright = Color(red: 0.30, green: 0.59, blue: 1.0)  // decorative fills only — ink text on top
    static let lime = Color(red: 0.55, green: 0.72, blue: 0.08)            // darkened lime for fills + ink text
    static let limeBright = Color(red: 0.78, green: 0.98, blue: 0.21)     // badges — ink text only
    static let sun = Color(red: 0.88, green: 0.68, blue: 0.0)             // darkened amber — ink text on top
    static let sunBright = Color(red: 1.0, green: 0.88, blue: 0.33)       // small badges only
    static let pink = Color(red: 0.78, green: 0.12, blue: 0.45)          // alert cards — white or ink
    static let pinkSoft = Color(red: 1.0, green: 0.82, blue: 0.91)        // alert card background
    static let mint = Color(red: 0.0, green: 0.55, blue: 0.48)            // section labels
    static let mintSoft = Color(red: 0.85, green: 1.0, blue: 0.96)        // card tint
    static let lavender = Color(red: 0.45, green: 0.35, blue: 0.78)
    static let lavenderSoft = Color(red: 0.91, green: 0.88, blue: 1.0)

    /// Navigation chrome — paper, not yellow, so system titles stay dark
    static let navBar = paper

    // MARK: Spacing

    static let spaceXS: CGFloat = 8
    static let spaceSM: CGFloat = 12
    static let spaceMD: CGFloat = 20
    static let spaceLG: CGFloat = 28
    static let spaceXL: CGFloat = 36
}

// MARK: - Accessible text helpers

extension View {
    func neoPrimaryText() -> some View {
        foregroundStyle(Neo.ink)
    }

    func neoSecondaryText() -> some View {
        foregroundStyle(Neo.inkSecondary)
    }

    func neoTertiaryText() -> some View {
        foregroundStyle(Neo.inkTertiary)
    }
}

// MARK: - Dividers & section spacing

struct NeoDivider: View {
    var body: some View {
        Rectangle()
            .fill(Neo.ink)
            .frame(height: 2)
            .padding(.vertical, Neo.spaceXS)
    }
}

extension View {
    func neoSectionSpacing() -> some View {
        padding(.vertical, Neo.spaceMD)
    }
}

// MARK: - Card

struct NeoCardModifier: ViewModifier {
    let fill: Color
    var shadowColor: Color = Neo.ink

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Neo.radius)
                    .fill(shadowColor)
                    .offset(x: Neo.shadow, y: Neo.shadow)
            )
            .background(
                RoundedRectangle(cornerRadius: Neo.radius)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Neo.radius)
                    .stroke(Neo.ink, lineWidth: Neo.border)
            )
    }
}

extension View {
    func neoCard(fill: Color = Neo.paper) -> some View {
        modifier(NeoCardModifier(fill: fill))
    }

    func neoScreen() -> some View {
        background(Neo.canvas.ignoresSafeArea())
    }
}

// MARK: - Buttons

struct NeoButtonStyle: ButtonStyle {
    let fill: Color
    var isCompact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .caption.weight(.black) : .headline.weight(.black))
            .foregroundStyle(Neo.ink)
            .padding(.horizontal, isCompact ? 10 : 18)
            .padding(.vertical, isCompact ? 6 : 12)
            .frame(maxWidth: isCompact ? nil : .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Neo.ink)
                    .offset(
                        x: configuration.isPressed ? 2 : Neo.shadow,
                        y: configuration.isPressed ? 2 : Neo.shadow
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isEnabled ? fill : fill.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Neo.ink, lineWidth: Neo.border)
            )
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
            .opacity(isEnabled ? 1 : 0.75)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct NeoIconBadge: View {
    let systemName: String
    let fill: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.title2.weight(.black))
            .foregroundStyle(Neo.ink)
            .frame(width: 52, height: 52)
            .neoCard(fill: fill)
    }
}

// MARK: - Typography

struct NeoTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .black, design: .rounded))
            .neoPrimaryText()
    }
}

struct NeoSectionLabel: View {
    let text: String
    let fill: Color

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.black))
            .tracking(1.2)
            .neoPrimaryText()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .neoCard(fill: fill)
    }
}

// MARK: - Text Field

struct NeoTextField: View {
    let label: String
    @Binding var text: String
    var placeholder = ""
    var autocapitalize: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NeoSectionLabel(text: label, fill: Neo.sun)

            TextField(placeholder, text: $text)
                .font(.body.weight(.semibold))
                .neoPrimaryText()
                .textInputAutocapitalization(autocapitalize)
                .autocorrectionDisabled()
                .padding(14)
                .neoCard(fill: Neo.paper)
        }
    }
}

// MARK: - Alert Banner

struct NeoAlertBanner: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            NeoIconBadge(systemName: "bell.fill", fill: Neo.pinkSoft)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.black))
                    .neoPrimaryText()
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .neoSecondaryText()
            }
            Spacer()
        }
        .padding(14)
        .neoCard(fill: Neo.pinkSoft)
    }
}

// MARK: - Role Button

struct NeoRoleButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let fill: Color

    var body: some View {
        HStack(spacing: 16) {
            NeoIconBadge(systemName: icon, fill: fill)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.black))
                    .neoPrimaryText()
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .neoSecondaryText()
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.headline.weight(.black))
                .neoPrimaryText()
        }
        .padding(16)
        .neoCard(fill: Neo.paper)
    }
}

// MARK: - Threshold Slider

struct ThresholdSlider: View {
    @Binding var value: Double
    var accent: Color = Neo.coral
    var showSectionLabel = false
    var sectionLabel = "Alert Distance"

    private let range: ClosedRange<Double> = 100...1000
    private let step: Double = 50

    var body: some View {
        VStack(alignment: .leading, spacing: Neo.spaceMD) {
            if showSectionLabel {
                NeoSectionLabel(text: sectionLabel, fill: accent)
            }

            Text("\(Int(value)) METERS")
                .font(.title2.weight(.black))
                .neoPrimaryText()

            NeoVolumeSlider(
                value: $value,
                range: range,
                step: step,
                accent: accent == Neo.electric ? Neo.electricBright : accent
            )

            HStack {
                Text("100 m")
                Spacer()
                Text("1 km")
            }
            .font(.caption.weight(.bold))
            .neoSecondaryText()
        }
    }
}

/// Volume-style slider with a draggable circular thumb on a neo-brutalist track.
struct NeoVolumeSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let accent: Color

    private let thumbSize: CGFloat = 32
    private let trackHeight: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let travelWidth = max(geo.size.width - thumbSize, 1)
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbOffset = fraction * travelWidth

            ZStack(alignment: .leading) {
                trackBackground(width: geo.size.width)

                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(accent)
                    .frame(width: thumbOffset + thumbSize / 2, height: trackHeight - 4)
                    .padding(.leading, 2)
                    .padding(.top, 2)

                sliderThumb
                    .offset(x: thumbOffset)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle().size(width: geo.size.width, height: thumbSize + 8))
            .gesture(dragGesture(travelWidth: travelWidth))
        }
        .frame(height: thumbSize + Neo.spaceSM)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Alert distance")
        .accessibilityValue("\(Int(value)) meters")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
            case .decrement:
                value = max(value - step, range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    private var sliderThumb: some View {
        ZStack {
            Circle()
                .fill(Neo.ink)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: 3, y: 3)
            Circle()
                .fill(Neo.paper)
                .frame(width: thumbSize, height: thumbSize)
            Circle()
                .stroke(Neo.ink, lineWidth: Neo.border)
                .frame(width: thumbSize, height: thumbSize)
            Circle()
                .fill(accent)
                .frame(width: 10, height: 10)
        }
    }

    private func trackBackground(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: trackHeight / 2)
                .fill(Neo.ink)
                .frame(width: width, height: trackHeight)
                .offset(x: 3, y: 3)
            RoundedRectangle(cornerRadius: trackHeight / 2)
                .fill(Neo.paper)
                .frame(width: width, height: trackHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .stroke(Neo.ink, lineWidth: 2)
                )
        }
    }

    private func dragGesture(travelWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                value = snappedValue(for: gesture.location.x, travelWidth: travelWidth)
            }
    }

    private func snappedValue(for x: CGFloat, travelWidth: CGFloat) -> Double {
        let clampedX = min(max(0, x - thumbSize / 2), travelWidth)
        let fraction = clampedX / travelWidth
        let raw = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
        let stepped = (raw / step).rounded() * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}

// MARK: - Map Markers

struct RunnerMapMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "figure.run")
                .font(.caption.weight(.black))
                .neoPrimaryText()
                .padding(10)
                .neoCard(fill: Neo.coral)
            Image(systemName: "triangle.fill")
                .font(.caption2.weight(.black))
                .neoPrimaryText()
                .rotationEffect(.degrees(180))
                .offset(y: -5)
        }
    }
}

struct SpectatorMapMarker: View {
    let isMe: Bool

    var body: some View {
        Image(systemName: isMe ? "person.fill" : "person")
            .font(.caption.weight(.black))
            .neoPrimaryText()
            .padding(10)
            .neoCard(fill: isMe ? Neo.electricBright : Neo.lavenderSoft)
    }
}

// MARK: - Navigation chrome

struct NeoNavBarModifier: ViewModifier {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Neo.navBar)
        appearance.shadowColor = UIColor(Neo.ink)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Neo.ink),
            .font: UIFont.systemFont(ofSize: 17, weight: .black),
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Neo.ink),
            .font: UIFont.systemFont(ofSize: 34, weight: .black),
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Neo.ink)
    }

    func body(content: Content) -> some View {
        content
            .toolbarBackground(Neo.navBar, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(Neo.ink)
    }
}

extension View {
    func neoNavigation() -> some View {
        modifier(NeoNavBarModifier())
    }
}
