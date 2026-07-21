import SwiftUI

/// Draggable bottom sheet with collapsed peek and expanded detail states.
struct NeoDraggableBottomSheet<Collapsed: View, Expanded: View>: View {
    @Binding var isExpanded: Bool
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    @ViewBuilder let collapsed: () -> Collapsed
    @ViewBuilder let expanded: () -> Expanded

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        let minH = collapsedHeight
        let maxH = expandedHeight
        let resting = isExpanded ? maxH : minH
        let height = clamp(resting - dragOffset, min: minH, max: maxH)

        VStack(spacing: 0) {
            dragHandle

            if isExpanded {
                ScrollView {
                    expanded()
                        .padding(.horizontal, Neo.spaceLG)
                        .padding(.bottom, Neo.spaceXL)
                }
            } else {
                collapsed()
                    .padding(.horizontal, Neo.spaceLG)
                    .padding(.bottom, Neo.spaceMD)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            isExpanded = true
                        }
                    }
            }
        }
        .frame(height: height, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(Neo.paper)
        .clipShape(RoundedRectangle(cornerRadius: Neo.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Neo.radius, style: .continuous)
                .stroke(Neo.ink, lineWidth: Neo.border)
        )
        .background(
            RoundedRectangle(cornerRadius: Neo.radius, style: .continuous)
                .fill(Neo.ink)
                .offset(x: Neo.shadow, y: Neo.shadow)
        )
        .gesture(dragGesture(minHeight: minH, maxHeight: maxH))
    }

    private var dragHandle: some View {
        VStack(spacing: Neo.spaceSM) {
            Capsule()
                .fill(Neo.ink)
                .frame(width: 44, height: 5)
                .padding(.top, Neo.spaceSM)

            if isExpanded {
                HStack {
                    Text("Details")
                        .font(.caption.weight(.black))
                        .neoSecondaryText()
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            isExpanded = false
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.black))
                            .neoPrimaryText()
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Neo.spaceLG)
            }
        }
        .padding(.bottom, Neo.spaceXS)
    }

    private func dragGesture(minHeight: CGFloat, maxHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let resting = isExpanded ? maxHeight : minHeight
                let projected = resting - value.translation.height
                let midpoint = (minHeight + maxHeight) / 2
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    isExpanded = projected > midpoint
                }
            }
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}
