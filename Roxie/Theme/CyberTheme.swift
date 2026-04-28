import SwiftUI

/// Cyberpunk HUD design tokens. Used to give Bonie a distinct visual
/// language vs. native (which is glass + soft pinks). Everything here is
/// dark base with neon cyan / magenta accents and monospaced tech text.
enum Cyber {
    // MARK: Palette

    static let bg = Color.black
    static let surface = Color(hex: "#0A0E1A")
    static let surfaceHi = Color(hex: "#12182B")
    static let cyan = Color(hex: "#00E5FF")
    static let magenta = Color(hex: "#FF2BD6")
    static let violet = Color(hex: "#8B5CF6")
    static let lime = Color(hex: "#9DFF00")
    static let amber = Color(hex: "#FFB800")
    static let danger = Color(hex: "#FF3B6E")

    static let text = Color.white
    static let textDim = Color.white.opacity(0.55)
    static let textMuted = Color.white.opacity(0.32)
    static let stroke = Color.white.opacity(0.08)

    // MARK: Typography helpers

    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - HUD primitives

/// Sharp-edged panel with a thin neon border + subtle glow. Workhorse
/// container for buttons, chips, and cards.
struct HUDPanel<Content: View>: View {
    var tint: Color = Cyber.cyan
    var corner: CGFloat = 6
    var fill: Color = Cyber.surface.opacity(0.7)
    var lineWidth: CGFloat = 1
    var glow: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(fill)
            content()
        }
        .background(.ultraThinMaterial.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(tint.opacity(0.85), lineWidth: lineWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .shadow(color: glow ? tint.opacity(0.45) : .clear, radius: glow ? 8 : 0, x: 0, y: 0)
    }
}

/// L-shaped brackets in each corner — a recurring HUD detail.
struct CornerBrackets: View {
    var tint: Color = Cyber.cyan
    var size: CGFloat = 10
    var thickness: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                bracket(at: .topLeading, in: CGSize(width: w, height: h))
                bracket(at: .topTrailing, in: CGSize(width: w, height: h))
                bracket(at: .bottomLeading, in: CGSize(width: w, height: h))
                bracket(at: .bottomTrailing, in: CGSize(width: w, height: h))
            }
        }
    }

    @ViewBuilder
    private func bracket(at corner: Alignment, in box: CGSize) -> some View {
        Path { p in
            switch corner {
            case .topLeading:
                p.move(to: CGPoint(x: 0, y: size))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: size, y: 0))
            case .topTrailing:
                p.move(to: CGPoint(x: box.width - size, y: 0))
                p.addLine(to: CGPoint(x: box.width, y: 0))
                p.addLine(to: CGPoint(x: box.width, y: size))
            case .bottomLeading:
                p.move(to: CGPoint(x: 0, y: box.height - size))
                p.addLine(to: CGPoint(x: 0, y: box.height))
                p.addLine(to: CGPoint(x: size, y: box.height))
            case .bottomTrailing:
                p.move(to: CGPoint(x: box.width - size, y: box.height))
                p.addLine(to: CGPoint(x: box.width, y: box.height))
                p.addLine(to: CGPoint(x: box.width, y: box.height - size))
            default:
                EmptyView()
            }
        }
        .stroke(tint, style: StrokeStyle(lineWidth: thickness, lineCap: .square))
    }
}

/// Hex-shaped icon button. Think of it as the cyber answer to a circular
/// glass pill.
struct HexButton<Label: View>: View {
    var tint: Color = Cyber.cyan
    var size: CGFloat = 48
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            ZStack {
                HexagonShape()
                    .fill(Cyber.surface.opacity(0.85))
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(HexagonShape())
                HexagonShape()
                    .stroke(tint.opacity(0.9), lineWidth: 1.2)
                label()
                    .foregroundStyle(tint)
            }
            .frame(width: size, height: size * 1.15)
            .shadow(color: tint.opacity(0.5), radius: 6, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let xQuarter = w / 4
        let xMid = w / 2
        let xRight = w
        let yMid = h / 2
        let yTop: CGFloat = 0
        let yBot = h

        var p = Path()
        p.move(to: CGPoint(x: 0, y: yMid))
        p.addLine(to: CGPoint(x: xQuarter, y: yTop))
        p.addLine(to: CGPoint(x: xQuarter * 3, y: yTop))
        p.addLine(to: CGPoint(x: xRight, y: yMid))
        p.addLine(to: CGPoint(x: xQuarter * 3, y: yBot))
        p.addLine(to: CGPoint(x: xQuarter, y: yBot))
        p.closeSubpath()
        _ = xMid
        return p
    }
}

/// Subtle horizontal scan line used as a divider / accent.
struct ScanLine: View {
    var tint: Color = Cyber.cyan
    var body: some View {
        LinearGradient(
            colors: [.clear, tint.opacity(0.6), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}

/// Tiny status dot with breathing pulse.
struct StatusDot: View {
    var tint: Color = Cyber.lime
    @State private var pulse = false
    var body: some View {
        Circle()
            .fill(tint)
            .frame(width: 6, height: 6)
            .shadow(color: tint, radius: pulse ? 5 : 2)
            .opacity(pulse ? 0.6 : 1)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
