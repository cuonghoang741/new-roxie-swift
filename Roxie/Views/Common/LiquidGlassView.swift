import SwiftUI

/// Approximation of the Callstack liquid-glass effect used in the RN app.
/// We rely on `.ultraThinMaterial` + a soft tint, which renders the same
/// frosted pill look on iOS 17+.
struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat = 20
    var tint: Color = .white.opacity(0.6)

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
    }
}

struct CurrencyBadge: View {
    enum Kind {
        case coin, ruby
        var systemImage: String {
            switch self {
            case .coin: return "dollarsign.circle.fill"
            case .ruby: return "diamond.fill"
            }
        }
        var tint: Color {
            switch self {
            case .coin: return Color(hex: "#F79009")
            case .ruby: return Palette.Brand.s500
            }
        }
    }

    var kind: Kind
    var amount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: kind.systemImage)
                .foregroundStyle(kind.tint)
            Text("\(amount)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.GrayDark.s900)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(LiquidGlassBackground(cornerRadius: 18))
    }
}
