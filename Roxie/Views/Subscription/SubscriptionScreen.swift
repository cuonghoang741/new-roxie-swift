import SwiftUI
import AVKit
import Combine

struct SubscriptionScreen: View {
    var onClose: () -> Void

    @Environment(VRMContext.self) private var vrm
    @State private var selectedPlan: Plan = .yearly
    @State private var player: AVPlayer?
    @State private var isProcessing = false
    @State private var playerReady: Bool = false
    @State private var statusCancellable: AnyCancellable?
    @State private var browserURL: URL?

    enum Plan: Hashable {
        case yearly, monthly
        var name: String { self == .yearly ? "ANNUAL" : "MONTHLY" }
        var priceString: String { self == .yearly ? "$59.99" : "$9.99" }
        var period: String { self == .yearly ? "PER YEAR" : "PER MONTH" }
        var subDetail: String? { self == .yearly ? "$5.00 / mo" : nil }
        var code: String { self == .yearly ? "PRO.A" : "PRO.M" }
    }

    private let perks: [(systemImage: String, text: String)] = [
        ("infinity", "UNLIMITED MESSAGES"),
        ("photo.stack.fill", "EXCLUSIVE MEDIA VAULT"),
        ("video.fill", "30 MIN VIDEO / MONTH"),
        ("person.2.fill", "15+ COMPANIONS UNLOCKED"),
        ("tshirt.fill", "FULL OUTFIT LIBRARY"),
        ("photo.on.rectangle.angled", "FULL BACKGROUND LIBRARY"),
    ]

    private var defaultVideoURL: URL? {
        URL(string: "https://pub-6671ed00c8d945b28ff7d8ec392f60b8.r2.dev/videos/Smiling_sweetly_to_202601061626_n3trm%20(online-video-cutter.com).mp4")
    }
    private var heroCharacter: CharacterItem? { vrm.currentCharacter }
    private var heroVideoURL: URL? {
        if let s = vrm.currentCostume?.videoUrl, let u = URL(string: s) { return u }
        if let s = heroCharacter?.videoUrl, let u = URL(string: s) { return u }
        return defaultVideoURL
    }
    private var discountText: String? {
        let monthly = 9.99 * 12.0
        let yearly = 59.99
        let pct = Int(((monthly - yearly) / monthly) * 100)
        return pct > 0 ? "-\(pct)%" : nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            Cyber.bg.ignoresSafeArea()

            videoBackdrop
            scanlineOverlay
            CyberGrid().opacity(0.18).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                bottomDeck
            }
        }
        .onAppear { setupPlayer() }
        .onChange(of: vrm.currentCharacter?.id) { _, _ in setupPlayer() }
        .onChange(of: vrm.currentCostume?.id) { _, _ in setupPlayer() }
        .onDisappear { player?.pause(); player = nil }
        .preferredColorScheme(.dark)
        .inAppBrowser(url: $browserURL)
    }

    // MARK: - Layers

    private var videoBackdrop: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: poster image as backdrop while video loads.
            if let img = heroCharacter?.thumbnailUrl ?? heroCharacter?.avatar,
               let url = URL(string: img) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Cyber.bg
                }
                .frame(maxWidth: .infinity)
                .frame(height: 540)
                .clipped()
                .id(heroCharacter?.id)
                .transition(.opacity)
            } else {
                Cyber.bg.frame(height: 540)
            }

            // Layer 2: video, only shown once first frame is ready.
            if let player, playerReady {
                FillVideoPlayer(player: player)
                    .frame(maxWidth: .infinity)
                    .frame(height: 540)
                    .clipped()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            LinearGradient(
                colors: [.clear, Cyber.bg.opacity(0.4), Cyber.bg, Cyber.bg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 540)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.25), value: playerReady)
    }

    private var scanlineOverlay: some View {
        VStack(spacing: 3) {
            ForEach(0..<60) { _ in
                Color.white.opacity(0.04).frame(height: 1)
                Color.clear.frame(height: 3)
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Text("//")
                    .font(Cyber.mono(13, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                Text("BONIE_OS  v1.0")
                    .font(Cyber.mono(11, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .tracking(1)
            }
            Spacer()
            Button(action: onClose) {
                ZStack {
                    Rectangle().fill(Cyber.surface.opacity(0.85))
                    Rectangle().stroke(Cyber.cyan.opacity(0.7), lineWidth: 1)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                }
                .frame(width: 38, height: 38)
                .shadow(color: Cyber.cyan.opacity(0.6), radius: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var bottomDeck: some View {
        VStack(spacing: 18) {
            heroBlock
            perksBlock
            planBlock
            ctaBlock
            footerLinks
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("[ TIER ]")
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(1.4)
                Text("PRO.UNLIMITED")
                    .font(Cyber.mono(11, weight: .heavy))
                    .foregroundStyle(Cyber.magenta)
                    .tracking(1.2)
                Spacer()
                StatusDot(tint: Cyber.lime)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("STAY")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(Cyber.text)
                Text("WITH//ME")
                    .font(Cyber.mono(28, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .shadow(color: Cyber.cyan.opacity(0.7), radius: 6)
            }
            Text("WITHOUT.LIMITS")
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(Cyber.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var perksBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(perks, id: \.text) { perk in
                HStack(spacing: 10) {
                    Image(systemName: perk.systemImage)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                        .frame(width: 18)
                    Text("//")
                        .font(Cyber.mono(11, weight: .heavy))
                        .foregroundStyle(Cyber.cyan.opacity(0.6))
                    Text(perk.text)
                        .font(Cyber.mono(11, weight: .semibold))
                        .foregroundStyle(Cyber.text)
                        .tracking(0.8)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Cyber.surface.opacity(0.7))
        .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.4), lineWidth: 1))
        .overlay(CornerBrackets(tint: Cyber.cyan, size: 8))
    }

    private var planBlock: some View {
        HStack(spacing: 10) {
            CyberPlanCard(
                code: Plan.yearly.code,
                name: Plan.yearly.name,
                price: Plan.yearly.priceString,
                period: Plan.yearly.period,
                subDetail: Plan.yearly.subDetail,
                badge: discountText,
                tint: Cyber.magenta,
                isSelected: selectedPlan == .yearly,
                onTap: { selectedPlan = .yearly }
            )
            CyberPlanCard(
                code: Plan.monthly.code,
                name: Plan.monthly.name,
                price: Plan.monthly.priceString,
                period: Plan.monthly.period,
                subDetail: nil,
                badge: nil,
                tint: Cyber.cyan,
                isSelected: selectedPlan == .monthly,
                onTap: { selectedPlan = .monthly }
            )
        }
    }

    private var ctaBlock: some View {
        Button {
            isProcessing = true
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                isProcessing = false
                onClose()
            }
        } label: {
            ZStack {
                LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing)
                if isProcessing {
                    ProgressView().tint(Cyber.bg)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.fill").font(.system(size: 14, weight: .heavy))
                        Text("INITIALIZE PRO//")
                            .font(Cyber.mono(14, weight: .heavy))
                            .tracking(1.4)
                    }
                    .foregroundStyle(Cyber.bg)
                }
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: Cyber.magenta.opacity(0.7), radius: 10)
        }
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.7 : 1)
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button { browserURL = AppConfig.Legal.privacy } label: { footerText(L10n.Cyber.subPrivacy) }
            Text("//").font(Cyber.mono(10, weight: .heavy)).foregroundStyle(Cyber.cyan.opacity(0.5))
            Button { } label: { footerText(L10n.Cyber.subRestore) }
            Text("//").font(Cyber.mono(10, weight: .heavy)).foregroundStyle(Cyber.cyan.opacity(0.5))
            Button { browserURL = AppConfig.Legal.terms } label: { footerText(L10n.Cyber.subTerms) }
        }
    }

    private func footerText(_ s: String) -> some View {
        Text(s)
            .font(Cyber.mono(10, weight: .heavy))
            .foregroundStyle(Cyber.textDim)
            .tracking(1.4)
    }

    private func setupPlayer() {
        guard let url = heroVideoURL else { return }
        playerReady = false
        statusCancellable?.cancel()

        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true
        p.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in p.seek(to: .zero); p.play() }

        statusCancellable = item.publisher(for: \.status, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { status in
                if status == .readyToPlay { playerReady = true }
            }

        player = p
        p.play()
    }
}

private struct CyberPlanCard: View {
    let code: String
    let name: String
    let price: String
    let period: String
    let subDetail: String?
    let badge: String?
    let tint: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(code)
                        .font(Cyber.mono(9, weight: .heavy))
                        .foregroundStyle(tint)
                        .tracking(1.4)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(Cyber.mono(10, weight: .heavy))
                            .foregroundStyle(Cyber.bg)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(tint)
                    }
                }
                Text(name)
                    .font(Cyber.mono(13, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.2)
                Text(price)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Cyber.text)
                Text(period)
                    .font(Cyber.mono(9, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .tracking(1)
                if let subDetail {
                    Text(subDetail)
                        .font(Cyber.mono(9, weight: .semibold))
                        .foregroundStyle(tint)
                        .tracking(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? tint.opacity(0.12) : Cyber.surface.opacity(0.78))
            .overlay(Rectangle().stroke(isSelected ? tint : tint.opacity(0.35), lineWidth: isSelected ? 1.5 : 1))
            .overlay(CornerBrackets(tint: tint, size: 8))
            .shadow(color: isSelected ? tint.opacity(0.6) : .clear, radius: isSelected ? 8 : 0)
        }
        .buttonStyle(.plain)
    }
}

/// AVPlayer wrapper that uses `.resizeAspectFill` so the video crops to fill
/// instead of letterboxing. SwiftUI's `VideoPlayer` doesn't expose this.
private struct FillVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let v = PlayerView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

private struct CyberGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 32
            let stroke = GraphicsContext.Shading.color(.white.opacity(0.06))
            for x in stride(from: 0, through: size.width, by: step) {
                var p = Path()
                p.move(to: .init(x: x, y: 0))
                p.addLine(to: .init(x: x, y: size.height))
                ctx.stroke(p, with: stroke, lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: step) {
                var p = Path()
                p.move(to: .init(x: 0, y: y))
                p.addLine(to: .init(x: size.width, y: y))
                ctx.stroke(p, with: stroke, lineWidth: 0.5)
            }
        }
    }
}
