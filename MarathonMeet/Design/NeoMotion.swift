import SwiftUI
import UIKit

// MARK: - Motion tokens

enum NeoMotion {
    static let press = Animation.easeOut(duration: 0.12)
    static let springSnappy = Animation.spring(response: 0.32, dampingFraction: 0.78)
    static let springSmooth = Animation.spring(response: 0.42, dampingFraction: 0.86)
    static let screen = Animation.spring(response: 0.48, dampingFraction: 0.88)
}

// MARK: - Haptics

enum NeoHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Card / button press styles

/// Neo-brutalist push-down for tappable cards (role picker, etc.)
/// Behaves like `.plain` so system button chrome cannot recolor fills.
struct NeoCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(1)
            .saturation(1)
            .offset(
                x: configuration.isPressed ? Neo.shadow : 0,
                y: configuration.isPressed ? Neo.shadow : 0
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(NeoMotion.press, value: configuration.isPressed)
            .sensoryFeedback(.impact(flex: .soft), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}

/// Subtle press for toolbar text buttons.
struct NeoToolbarPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(NeoMotion.press, value: configuration.isPressed)
    }
}

// MARK: - Appear animations

private struct NeoStaggeredAppearModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 18)
            .scaleEffect(isVisible ? 1 : 0.97)
            .onAppear {
                withAnimation(NeoMotion.springSmooth.delay(baseDelay * Double(index))) {
                    isVisible = true
                }
            }
    }
}

private struct NeoPopInModifier: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.92)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(NeoMotion.springSnappy) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Fade + slide up with staggered delay (home cards, dashboard sections).
    func neoStaggeredAppear(index: Int, baseDelay: Double = 0.07) -> some View {
        modifier(NeoStaggeredAppearModifier(index: index, baseDelay: baseDelay))
    }

    /// Quick pop-in for newly revealed content (session code, alerts).
    func neoPopIn() -> some View {
        modifier(NeoPopInModifier())
    }

    /// Standard screen transition when swapping root views.
    func neoScreenTransition() -> some View {
        transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }
}
