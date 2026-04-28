import SwiftUI

struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Cyber.cyan)
                .frame(width: 2)
                .shadow(color: Cyber.cyan.opacity(0.8), radius: 4)
            HStack(spacing: 6) {
                Text("AGT//")
                    .font(Cyber.mono(9, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(1.4)
                ForEach(0..<3) { i in
                    Rectangle()
                        .fill(Cyber.cyan)
                        .frame(width: 4, height: animate ? 10 : 4)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.12),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Cyber.surface.opacity(0.85))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 6, topTrailingRadius: 6)
                .stroke(Cyber.cyan.opacity(0.4), lineWidth: 1)
        )
        .clipShape(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 6, topTrailingRadius: 6)
        )
        .onAppear { animate = true }
    }
}
