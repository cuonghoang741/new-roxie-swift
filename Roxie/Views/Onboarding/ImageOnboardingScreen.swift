import SwiftUI

struct ImageOnboardingScreen: View {
    var onFinish: () -> Void
    @State private var page: Int = 0

    private let slides: [(String, String, String)] = [
        ("heart.circle.fill", "Chào bạn!", "Roxie giúp bạn tạo nhân vật ảo của riêng mình."),
        ("sparkles", "Cá nhân hoá", "Thay đổi trang phục, dance, bối cảnh theo ý thích."),
        ("message.fill", "Trò chuyện", "Nhắn tin, gọi thoại với nhân vật bất cứ khi nào.")
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.Brand.s200, Palette.Brand.s500], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { idx in
                        let slide = slides[idx]
                        VStack(spacing: 20) {
                            Image(systemName: slide.0)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .foregroundStyle(.white)
                                .shadow(radius: 12)
                            Text(slide.1)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            Text(slide.2)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 24)
                            Spacer()
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxHeight: .infinity)

                BrandButton(title: page == slides.count - 1 ? "Bắt đầu" : "Tiếp tục") {
                    if page < slides.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
