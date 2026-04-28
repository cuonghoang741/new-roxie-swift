import SwiftUI

struct VRMUIOverlay: View {
    @Environment(VRMContext.self) private var vrm
    @Environment(AppRootModel.self) private var root
    @Environment(RemoteSettings.self) private var remote

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
            // LEFT rail — Pro + call quota
            VStack(spacing: 14) {
                if !isPro && remote.bool("show_btn_pro") {
                    HexButton(tint: Cyber.magenta, size: 52) {
                        root.showSubscriptionSheet = true
                    } label: {
                        Image(systemName: "diamond.fill").font(.system(size: 16, weight: .heavy))
                    }
                }
                if remote.bool("show_btn_voice_call") {
                    HexButton(tint: Cyber.lime, size: 52) {
                        onStartCall()
                    } label: {
                        Image(systemName: "phone.fill").font(.system(size: 16, weight: .heavy))
                    }
                }
            }

            Spacer()

            // RIGHT rail — controls
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(Cyber.surface.opacity(0.85))
                        .background(.ultraThinMaterial.opacity(0.4))
                    VStack(spacing: 14) {
                        if remote.bool("show_btn_costume") {
                            railIcon("tshirt.fill", tint: Cyber.cyan) { root.showCostumeSheet = true }
                        }
                        if remote.bool("show_btn_background") {
                            railIcon("photo.on.rectangle", tint: Cyber.cyan) { root.showBackgroundSheet = true }
                        }
                        if remote.bool("show_btn_chat_list") {
                            railIcon(showChatList ? "rectangle.3.group.bubble.fill" : "rectangle.3.group.bubble",
                                     tint: Cyber.cyan) {
                                onToggleChatList()
                            }
                        }
                        if remote.bool("show_btn_bgm") {
                            railIcon(isBgmOn ? "waveform" : "waveform.slash",
                                     tint: isBgmOn ? Cyber.lime : Cyber.cyan) {
                                onToggleBGM()
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 10)

                    CornerBrackets(tint: Cyber.cyan, size: 8, thickness: 1.2)
                }
                .frame(width: 56)
                .overlay(
                    Rectangle()
                        .stroke(Cyber.cyan.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: Cyber.cyan.opacity(0.35), radius: 8)
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func railIcon(_ system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image(systemName: system)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .shadow(color: tint.opacity(0.8), radius: 4)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Top header (HUD)

struct SceneHeader: View {
    let character: CharacterItem?
    var onOpenSettings: () -> Void
    var onOpenCharacters: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HexButton(tint: Cyber.cyan, size: 44, action: onOpenSettings) {
                Image(systemName: "gearshape.fill").font(.system(size: 14, weight: .heavy))
            }

            Spacer()

            characterPlate

            Spacer()

            HexButton(tint: Cyber.magenta, size: 44, action: onOpenCharacters) {
                Image(systemName: "square.grid.2x2.fill").font(.system(size: 14, weight: .heavy))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    private var characterPlate: some View {
        let name = character?.name ?? "—"
        return HStack(spacing: 8) {
            StatusDot(tint: Cyber.lime)
            Text("//")
                .font(Cyber.mono(11, weight: .bold))
                .foregroundStyle(Cyber.cyan)
            Text(name.uppercased())
                .font(Cyber.mono(13, weight: .bold))
                .foregroundStyle(Cyber.text)
                .lineLimit(1)
            Text(L10n.Cyber.online)
                .font(Cyber.mono(9, weight: .heavy))
                .foregroundStyle(Cyber.lime)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .overlay(Rectangle().stroke(Cyber.lime.opacity(0.6), lineWidth: 1))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Cyber.surface.opacity(0.78))
        .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.85), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .shadow(color: Cyber.cyan.opacity(0.45), radius: 6)
        .fixedSize()
    }
}
