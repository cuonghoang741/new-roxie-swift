import SwiftUI
import AVKit

struct SubscriptionScreen: View {
    var onClose: () -> Void

    @Environment(VRMContext.self) private var vrm
    @State private var selectedPlan: Plan = .yearly
    @State private var player: AVPlayer?
    @State private var isProcessing = false

    enum Plan: Hashable {
        case yearly, monthly

        var name: String { self == .yearly ? "Yearly" : "Monthly" }
        var priceString: String { self == .yearly ? "$59.99" : "$9.99" }
        var period: String { self == .yearly ? "per year" : "per month" }
        var subDetail: String? { self == .yearly ? "$5.00/per month" : nil }
    }

    private let features: [(systemImage: String, text: String)] = [
        ("infinity", "Unlimited messages, no daily limits"),
        ("photo.stack.fill", "Access secreted photos and videos"),
        ("video.fill", "30 minutes of video calls each month"),
        ("person.2.fill", "Unlock 15+ and all upcoming girlfriends"),
        ("tshirt.fill", "Unlimited outfits"),
        ("photo.on.rectangle.angled", "Unlimited backgrounds"),
    ]

    private var defaultVideoURL: URL? {
        URL(string: "https://pub-6671ed00c8d945b28ff7d8ec392f60b8.r2.dev/videos/Smiling_sweetly_to_202601061626_n3trm%20(online-video-cutter.com).mp4")
    }

    private var heroVideoURL: URL? {
        if let s = vrm.currentCostume?.videoUrl, let u = URL(string: s) { return u }
        if let s = vrm.currentCharacter?.videoUrl, let u = URL(string: s) { return u }
        return defaultVideoURL
    }

    private var discountText: String? {
        // Yearly $59.99 vs Monthly $9.99 * 12 = $119.88 → ~50% savings
        let monthly = 9.99 * 12.0
        let yearly = 59.99
        let pct = Int(((monthly - yearly) / monthly) * 100)
        return pct > 0 ? "\(pct)% OFF" : nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            videoHeader
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomSheet
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { player?.pause() }
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
    }

    // MARK: - Top half: video + gradient

    private var videoHeader: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if let player {
                    VideoPlayer(player: player)
                        .disabled(true)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height * 0.65)
                        .clipped()
                } else {
                    Color.black
                        .frame(width: geo.size.width, height: geo.size.height * 0.65)
                }

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.8), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: geo.size.height * 0.65 * 0.5)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    // MARK: - Top bar (close button)

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(Color.white.opacity(0.9))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Bottom: hero + features + plans + cta + footer

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    proBadge
                    Text("Stay With Me\nWithout Limits")
                        .font(.system(size: 32, weight: .heavy))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .lineSpacing(4)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(features, id: \.text) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: feature.systemImage)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                Text(feature.text)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 16) {
                planCards
                upgradeButton
                footerLinks
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var proBadge: some View {
        HStack(spacing: 8) {
            Text("Bonie")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text("Pro")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#FFD91B"), Color(hex: "#FFE979")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color.black.opacity(0.6))
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var planCards: some View {
        HStack(spacing: 12) {
            PlanCard(
                title: "Yearly",
                price: Plan.yearly.priceString,
                period: Plan.yearly.period,
                subDetail: Plan.yearly.subDetail,
                badge: selectedPlan == .yearly ? discountText : nil,
                isSelected: selectedPlan == .yearly,
                onTap: { selectedPlan = .yearly }
            )
            PlanCard(
                title: "Monthly",
                price: Plan.monthly.priceString,
                period: Plan.monthly.period,
                subDetail: nil,
                badge: nil,
                isSelected: selectedPlan == .monthly,
                onTap: { selectedPlan = .monthly }
            )
        }
    }

    private var upgradeButton: some View {
        Button {
            isProcessing = true
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                isProcessing = false
                onClose()
            }
        } label: {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FFD91B"), Color(hex: "#FFE979")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                if isProcessing {
                    ProgressView().tint(.black)
                } else {
                    Text("Upgrade")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.7 : 1)
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Link("Privacy Policy", destination: AppConfig.Legal.privacy)
                .font(.system(size: 12))
                .foregroundStyle(.white)
            Text("|").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.3))
            Button("Restore Purchase") {}
                .font(.system(size: 12))
                .foregroundStyle(.white)
            Text("|").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.3))
            Link("Terms of Use", destination: AppConfig.Legal.terms)
                .font(.system(size: 12))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Player

    private func setupPlayer() {
        guard let url = heroVideoURL else { return }
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true
        p.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            p.seek(to: .zero)
            p.play()
        }
        player = p
        p.play()
    }
}

private struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let subDetail: String?
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(price)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text(period)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.6))
                if let subDetail {
                    Text(subDetail)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color(hex: "#2196F3").opacity(0.15) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color(hex: "#2196F3") : .clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "#2196F3"))
                        )
                        .offset(x: 4, y: -12)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
