import SwiftUI

struct VRMUIOverlay: View {
    @Environment(VRMContext.self) private var vrm
    @Environment(AppRootModel.self) private var root
    @Environment(\.isDarkBackground) private var isDark

    var onOpenSettings: () -> Void
    var onTriggerDance: () -> Void
    var onToggleBGM: () -> Void
    var onStartCall: () -> Void
    var onToggleChatList: () -> Void
    var isBgmOn: Bool
    var showChatList: Bool

    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        @Bindable var root = root

        HStack(alignment: .top, spacing: 0) {
            // LEFT column — Go Pro + Call quota
            VStack(spacing: 12) {
                if !isPro {
                    GoProButton { root.showSubscriptionSheet = true }
                }
                CallQuotaButton { onStartCall() }
            }

            Spacer()

            // RIGHT column — Outfit / Background / Chat toggle / Music
            VStack(spacing: 12) {
                OverlayIconButton(systemImage: "tshirt.fill") {
                    root.showCostumeSheet = true
                }
                OverlayIconButton(systemImage: "photo.on.rectangle") {
                    root.showBackgroundSheet = true
                }
                OverlayIconButton(
                    systemImage: showChatList ? "message.fill" : "message.badge.filled.fill"
                ) {
                    onToggleChatList()
                }
                OverlayIconButton(
                    systemImage: isBgmOn ? "speaker.wave.2.fill" : "speaker.slash.fill"
                ) {
                    onToggleBGM()
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Top header

struct SceneHeader: View {
    @Environment(\.isDarkBackground) private var isDark
    let character: CharacterItem?
    var onOpenSettings: () -> Void
    var onOpenCharacters: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            HeaderIconButton(systemImage: "gearshape.fill", action: onOpenSettings)

            Spacer()

            if let name = character?.name, !name.isEmpty {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ScenePalette.foreground(isDark: isDark))
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(LiquidGlassBackground(cornerRadius: 999, tint: ScenePalette.glassTint(isDark: isDark)))
            }

            Spacer()

            HeaderIconButton(systemImage: "square.grid.2x2.fill", action: onOpenCharacters)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Buttons

private struct OverlayIconButton: View {
    @Environment(\.isDarkBackground) private var isDark
    let systemImage: String
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(ScenePalette.foreground(isDark: isDark))
                .background(LiquidGlassBackground(cornerRadius: 22, tint: ScenePalette.glassTint(isDark: isDark)))
        }
    }
}

private struct HeaderIconButton: View {
    @Environment(\.isDarkBackground) private var isDark
    let systemImage: String
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(ScenePalette.foreground(isDark: isDark))
                .background(LiquidGlassBackground(cornerRadius: 22, tint: ScenePalette.glassTint(isDark: isDark)))
        }
    }
}

private struct GoProButton: View {
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            ZStack {
                Circle().fill(Color(hex: "#FF5CA8"))
                Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 2)
                Image("DiamondPink")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 18)
            }
            .frame(width: 44, height: 44)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color(hex: "#FF3B30"))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 2))
                    .offset(x: 2, y: -2)
            }
        }
    }
}

private struct CallQuotaButton: View {
    @Environment(\.isDarkBackground) private var isDark
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            ZStack {
                LiquidGlassBackground(cornerRadius: 22, tint: ScenePalette.glassTint(isDark: isDark))
                Circle()
                    .strokeBorder(ScenePalette.foreground(isDark: isDark).opacity(0.2), lineWidth: 2)
                Image(systemName: "phone.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ScenePalette.foreground(isDark: isDark))
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        }
    }
}
