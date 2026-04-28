import SwiftUI

struct NewUserGiftScreen: View {
    var onClaim: () -> Void
    @State private var glow = false

    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            CyberGridBackdrop().opacity(0.18).ignoresSafeArea()
            ScanLineBackdrop().ignoresSafeArea()
            RadialGradient(
                colors: [Cyber.magenta.opacity(0.4), .clear],
                center: .center, startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                ZStack {
                    HexagonShape()
                        .stroke(Cyber.magenta.opacity(0.7), lineWidth: 2)
                        .shadow(color: Cyber.magenta.opacity(glow ? 0.9 : 0.3), radius: glow ? 20 : 8)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 64, weight: .heavy))
                        .foregroundStyle(Cyber.magenta)
                        .shadow(color: Cyber.magenta.opacity(0.7), radius: 10)
                }
                .frame(width: 160, height: 184)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glow)

                VStack(spacing: 10) {
                    Text("[ AIRDROP.01 ]")
                        .font(Cyber.mono(11, weight: .heavy))
                        .foregroundStyle(Cyber.magenta)
                        .tracking(2)
                    Text("//WELCOME_PACK")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(Cyber.text)
                        .tracking(1.4)
                    Text(L10n.giftBody.uppercased())
                        .font(Cyber.mono(12, weight: .semibold))
                        .foregroundStyle(Cyber.textDim)
                        .multilineTextAlignment(.center)
                        .tracking(1.2)
                        .lineSpacing(4)
                        .padding(.horizontal, 30)
                }

                Spacer()

                Button(action: onClaim) {
                    HStack(spacing: 10) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 13, weight: .heavy))
                        Text("CLAIM_AIRDROP //")
                            .font(Cyber.mono(13, weight: .heavy))
                            .tracking(1.6)
                    }
                    .foregroundStyle(Cyber.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: Cyber.magenta.opacity(0.7), radius: 12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .onAppear { glow = true }
        .preferredColorScheme(.dark)
    }
}
