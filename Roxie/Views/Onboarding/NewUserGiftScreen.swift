import SwiftUI

struct NewUserGiftScreen: View {
    var onClaim: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.Brand.s500, Palette.Brand.s900], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "gift.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .foregroundStyle(.white)
                    .shadow(radius: 20)
                Text(L10n.giftTitle)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(L10n.giftBody)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                Spacer()
                PrimaryButton(title: L10n.giftClaim, action: onClaim)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }
}
