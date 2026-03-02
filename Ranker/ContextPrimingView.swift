import SwiftUI

struct ContextPrimingView: View {
    @Binding var showRanking: Bool

    private let contextItems = [
        "The Ethereum presale was July 22 \u{2013} Sep 2, 2014",
        "Bitcoin was ~$600 at the time",
        "You created this password on a web form at ethereum.org",
        "Take a moment: what browser were you using? What was your desktop wallpaper?",
        "What music were you listening to in summer 2014?",
        "Where were you living? What was your daily routine like?"
    ]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Context Priming")
                .font(.title2)
                .fontWeight(.bold)

            Text("Before ranking, immerse yourself in 2014")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(contextItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .padding(.top, 6)
                            .foregroundColor(.orange)
                        Text(item)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.05))
            .cornerRadius(12)

            Spacer()

            Button("Ready \u{2014} Start Ranking") {
                showRanking = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }
}
