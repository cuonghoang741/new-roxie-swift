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
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Cyber.cyan)
                    }
                    Text(toast.text.uppercased())
                        .font(Cyber.mono(11, weight: .heavy))
                        .foregroundStyle(Cyber.text)
                        .tracking(1.4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Cyber.surface.opacity(0.92))
                .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.7), lineWidth: 1))
                .overlay(CornerBrackets(tint: Cyber.cyan, size: 7))
                .shadow(color: Cyber.cyan.opacity(0.5), radius: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))
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
