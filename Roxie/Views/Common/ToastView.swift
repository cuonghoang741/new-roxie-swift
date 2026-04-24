import SwiftUI

struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let text: String
    let systemImage: String?
}

struct ToastOverlay: View {
    let toast: ToastMessage?

    var body: some View {
        VStack {
            if let toast {
                HStack(spacing: 8) {
                    if let icon = toast.systemImage {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(toast.text)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(Color.black.opacity(0.75))
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(toast.id)
            }
            Spacer()
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast)
    }
}
