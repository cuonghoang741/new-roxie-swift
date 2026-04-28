import SwiftUI

struct VoiceLoadingOverlay: View {
    let visible: Bool
    var characterName: String = "Character"
    var avatarURL: String?
    var backgroundURL: String?

    var body: some View {
        ZStack {
            if let backgroundURL, let url = URL(string: backgroundURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { Cyber.bg }
                .ignoresSafeArea()
            }
            if let avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { Cyber.bg.opacity(0.5) }
                .ignoresSafeArea()
            }
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Cyber.bg.opacity(0.55).ignoresSafeArea()
            scanlines

            VStack(spacing: 18) {
                Text(L10n.Cyber.establishingLink)
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(2)

                avatarBubble
                    .padding(.top, 4)

                VStack(spacing: 4) {
                    Text(characterName.uppercased())
                        .font(Cyber.mono(20, weight: .heavy))
                        .foregroundStyle(Cyber.text)
                        .tracking(2)
                    HStack(spacing: 6) {
                        StatusDot(tint: Cyber.lime)
                        Text(L10n.Cyber.connecting)
                            .font(Cyber.mono(11, weight: .heavy))
                            .foregroundStyle(Cyber.lime)
                            .tracking(1.6)
                        PulseDot(delay: 0)
                        PulseDot(delay: 0.2)
                        PulseDot(delay: 0.4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(visible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: visible)
        .allowsHitTesting(visible)
    }

    private var avatarBubble: some View {
        ZStack {
            HexagonShape().fill(Cyber.bg.opacity(0.5))
            HexagonShape().stroke(Cyber.cyan.opacity(0.7), lineWidth: 1.5)
            if let avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Cyber.cyan.opacity(0.6))
                }
                .frame(width: 110, height: 124)
                .clipShape(HexagonShape())
            }
        }
        .frame(width: 130, height: 150)
        .shadow(color: Cyber.cyan.opacity(0.7), radius: 16)
    }

    private var scanlines: some View {
        VStack(spacing: 3) {
            ForEach(0..<60) { _ in
                Color.white.opacity(0.05).frame(height: 1)
                Color.clear.frame(height: 3)
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct PulseDot: View {
    let delay: Double
    @State private var pulse = false

    var body: some View {
        Rectangle()
            .fill(Cyber.lime)
            .frame(width: 4, height: 4)
            .scaleEffect(pulse ? 1.4 : 0.8)
            .opacity(pulse ? 0.4 : 1)
            .shadow(color: Cyber.lime.opacity(0.8), radius: pulse ? 4 : 1)
            .animation(.easeInOut(duration: 0.6).repeatForever().delay(delay), value: pulse)
            .onAppear { pulse = true }
    }
}
