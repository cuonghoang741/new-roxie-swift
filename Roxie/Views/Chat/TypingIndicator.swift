import SwiftUI

struct TypingIndicator: View {
    @State private var opacities: [Double] = [0.3, 0.3, 0.3]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { idx in
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                    .opacity(opacities[idx])
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(red: 1.0, green: 0.43, blue: 0.63).opacity(0.3))
        .clipShape(Capsule())
        .onAppear {
            animate()
        }
    }

    private func animate() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                    opacities[i] = 1
                }
            }
        }
    }
}
