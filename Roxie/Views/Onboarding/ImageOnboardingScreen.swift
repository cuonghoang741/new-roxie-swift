import SwiftUI

struct ImageOnboardingScreen: View {
    var onFinish: () -> Void
    @State private var page: Int = 0

    private struct Slide {
        let icon: String
        let code: String
        let title: String
        let body: String
        let tint: Color
    }

    private let slides: [Slide] = [
        .init(icon: "circle.hexagongrid.fill", code: "BOOT.01", title: "//WELCOME",
              body: "Bonie initializes a private companion that lives just for you.", tint: Cyber.cyan),
        .init(icon: "tshirt.fill", code: "MOD.02", title: "//CUSTOMIZE",
              body: "Swap outfits, environments and choreography on the fly.", tint: Cyber.magenta),
        .init(icon: "waveform", code: "LINK.03", title: "//CONNECT",
              body: "Talk, chat and call your companion anytime, anywhere.", tint: Cyber.violet),
    ]

    private var current: Slide { slides[page] }

    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            CyberGridBackdrop().opacity(0.18).ignoresSafeArea()
            ScanLineBackdrop().ignoresSafeArea()
            RadialGradient(
                colors: [current.tint.opacity(0.35), .clear],
                center: .top, startRadius: 0, endRadius: 360
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: page)

            VStack(spacing: 0) {
                topStrip
                Spacer(minLength: 0)
                slideContent
                Spacer(minLength: 0)
                pagerDots
                ctaButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topStrip: some View {
        HStack {
            HStack(spacing: 6) {
                Text("//")
                    .font(Cyber.mono(11, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                Text("BONIE_OS  v1.0")
                    .font(Cyber.mono(10, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .tracking(1.4)
            }
            Spacer()
            Button {
                onFinish()
            } label: {
                Text("SKIP //")
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(1.4)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.5), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var slideContent: some View {
        VStack(spacing: 24) {
            ZStack {
                HexagonShape()
                    .stroke(current.tint.opacity(0.7), lineWidth: 2)
                    .shadow(color: current.tint.opacity(0.7), radius: 14)
                Image(systemName: current.icon)
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundStyle(current.tint)
                    .shadow(color: current.tint.opacity(0.6), radius: 8)
            }
            .frame(width: 160, height: 184)
            .id(current.code)
            .transition(.scale.combined(with: .opacity))

            VStack(spacing: 12) {
                Text("[\(current.code)]")
                    .font(Cyber.mono(11, weight: .heavy))
                    .foregroundStyle(current.tint)
                    .tracking(2)
                Text(current.title)
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(Cyber.text)
                    .tracking(1)
                Text(current.body.uppercased())
                    .font(Cyber.mono(12, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .multilineTextAlignment(.center)
                    .tracking(1.2)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: page)
    }

    private var pagerDots: some View {
        HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { i in
                Rectangle()
                    .fill(i == page ? current.tint : Cyber.textMuted)
                    .frame(width: i == page ? 24 : 8, height: 3)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
        .padding(.bottom, 18)
    }

    private var ctaButton: some View {
        Button {
            if page < slides.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
            } else {
                onFinish()
            }
        } label: {
            HStack(spacing: 10) {
                Text(page == slides.count - 1 ? "INITIALIZE //" : "NEXT //")
                    .font(Cyber.mono(13, weight: .heavy))
                    .tracking(1.6)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(Cyber.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LinearGradient(colors: [Cyber.cyan, current.tint], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: current.tint.opacity(0.6), radius: 10)
        }
    }
}
