import SwiftUI

/// In-app splash shown while we restore the auth session. Uses the same
/// cyber HUD vocabulary as the rest of the app so the launch → restore →
/// experience transition reads as one continuous animation.
struct CyberLaunchView: View {
    @State private var glow = false
    @State private var sweep: CGFloat = -1

    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            CyberGridBackdrop().opacity(0.18).ignoresSafeArea()
            ScanLineBackdrop().ignoresSafeArea()
            RadialGradient(
                colors: [Cyber.cyan.opacity(0.25), .clear],
                center: .center, startRadius: 0, endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    HexagonShape()
                        .stroke(Cyber.cyan.opacity(0.7), lineWidth: 2)
                        .shadow(color: Cyber.cyan.opacity(glow ? 0.9 : 0.3), radius: glow ? 22 : 6)
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                        .shadow(color: Cyber.cyan.opacity(0.8), radius: 8)
                }
                .frame(width: 130, height: 150)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glow)

                VStack(spacing: 6) {
                    Text("BONIE")
                        .font(.system(size: 36, weight: .black, design: .default))
                        .foregroundStyle(Cyber.text)
                        .tracking(8)
                        .shadow(color: Cyber.cyan.opacity(0.6), radius: 6)
                    Text("//SYSTEM_OS  v1.0")
                        .font(Cyber.mono(11, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                        .tracking(2)
                }

                bootBar
                    .frame(width: 200)
                    .padding(.top, 6)
            }
        }
        .onAppear {
            glow = true
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                sweep = 1
            }
        }
    }

    private var bootBar: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.Cyber.booting)
                .font(Cyber.mono(9, weight: .heavy))
                .foregroundStyle(Cyber.textDim)
                .tracking(1.6)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Cyber.surface.opacity(0.85))
                    .frame(height: 4)
                    .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.4), lineWidth: 0.5))
                GeometryReader { geo in
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, Cyber.cyan, .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 80, height: 4)
                        .offset(x: (geo.size.width + 80) * sweep - 80)
                        .shadow(color: Cyber.cyan.opacity(0.8), radius: 4)
                        .clipped()
                }
                .frame(height: 4)
            }
        }
    }
}
