import SwiftUI

struct HapticButton<Label: View>: View {
    var style: Haptics.Style = .light
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button {
            Haptics.fire(style)
            action()
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String?
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        HapticButton(style: .medium, action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Palette.GrayDark.s900)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct BrandButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        HapticButton(style: .medium, action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Palette.Brand.s500)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
