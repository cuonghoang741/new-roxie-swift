import SwiftUI

struct VoiceLoadingOverlay: View {
    let visible: Bool
    var characterName: String = "Character"
    var avatarURL: String?
    var backgroundURL: String?

    var body: some View {
        ZStack {
            // Background image (character/scene), then blur + dim
            if let backgroundURL, let url = URL(string: backgroundURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { Color.black }
                .ignoresSafeArea()
            }

            if let avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { Color.black.opacity(0.5) }
                .ignoresSafeArea()
            }

            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.4).ignoresSafeArea()

            // Centered content
            VStack(spacing: 16) {
                avatarBubble

                Text(characterName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 1)

                HStack(spacing: 6) {
                    PulseDot(delay: 0)
                    PulseDot(delay: 0.2)
                    PulseDot(delay: 0.4)
                    Text("Calling")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.leading, 4)
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
            Circle()
                .fill(Color.white.opacity(0.1))
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))

            if let avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(width: 112, height: 112)
                .clipShape(Circle())
            }
        }
        .frame(width: 120, height: 120)
    }
}

private struct PulseDot: View {
    let delay: Double
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.85))
            .frame(width: 6, height: 6)
            .scaleEffect(pulse ? 1.4 : 0.8)
            .opacity(pulse ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.6).repeatForever().delay(delay), value: pulse)
            .onAppear { pulse = true }
    }
}
