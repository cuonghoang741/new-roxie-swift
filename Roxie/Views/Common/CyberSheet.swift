import SwiftUI

/// Shared cyber-themed chrome for all bottom-sheet style modals.
/// Use as the root inside a `NavigationStack`-replacement: it draws the
/// dark grid background, a mono header, and a close hex button.
struct CyberSheetChrome<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var tint: Color = Cyber.cyan
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            CyberGridBackdrop().opacity(0.18).ignoresSafeArea()
            ScanLineBackdrop().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().background(tint.opacity(0.4))
                content()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("//")
                .font(Cyber.mono(13, weight: .heavy))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(Cyber.mono(13, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.6)
                if let subtitle {
                    Text(subtitle.uppercased())
                        .font(Cyber.mono(9, weight: .semibold))
                        .foregroundStyle(Cyber.textDim)
                        .tracking(1.4)
                }
            }

            Spacer()

            Button { dismiss() } label: {
                ZStack {
                    Rectangle().fill(Cyber.surface.opacity(0.85))
                    Rectangle().stroke(tint.opacity(0.7), lineWidth: 1)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(tint)
                }
                .frame(width: 36, height: 36)
                .shadow(color: tint.opacity(0.5), radius: 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 14)
    }
}

/// Grid pattern used as a backdrop under sheet content.
struct CyberGridBackdrop: View {
    var step: CGFloat = 32
    var tint: Color = .white.opacity(0.06)

    var body: some View {
        Canvas { ctx, size in
            let s = GraphicsContext.Shading.color(tint)
            for x in stride(from: 0, through: size.width, by: step) {
                var p = Path()
                p.move(to: .init(x: x, y: 0))
                p.addLine(to: .init(x: x, y: size.height))
                ctx.stroke(p, with: s, lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: step) {
                var p = Path()
                p.move(to: .init(x: 0, y: y))
                p.addLine(to: .init(x: size.width, y: y))
                ctx.stroke(p, with: s, lineWidth: 0.5)
            }
        }
    }
}

struct ScanLineBackdrop: View {
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<80) { _ in
                Color.white.opacity(0.025).frame(height: 1)
                Color.clear.frame(height: 3)
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}

/// Lock overlay used by every catalog tile when the item is gated behind
/// pro and the user is not pro.
struct CyberLockOverlay: View {
    var body: some View {
        ZStack {
            Cyber.bg.opacity(0.55)
            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .shadow(color: Cyber.cyan.opacity(0.7), radius: 5)
                Text("PRO")
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.bg)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing))
                    .tracking(1.4)
            }
            CornerBrackets(tint: Cyber.cyan, size: 8)
        }
    }
}

struct CyberOwnedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10, weight: .heavy))
            Text(L10n.Cyber.owned)
                .font(Cyber.mono(9, weight: .heavy))
                .tracking(1.4)
        }
        .foregroundStyle(Cyber.lime)
    }
}

struct CyberFreeBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gift.fill")
                .font(.system(size: 10, weight: .heavy))
            Text(L10n.Cyber.free)
                .font(Cyber.mono(9, weight: .heavy))
                .tracking(1.4)
        }
        .foregroundStyle(Cyber.lime)
    }
}
