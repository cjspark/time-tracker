import SwiftUI

struct MoodPickerView: View {
    @Binding var mood: Int?

    // 1=😩很差, 5=😄很好 — matches web app semantic
    private let emojis = ["", "😩", "😕", "😐", "🙂", "😄"]
    private let labels = ["", "很差", "较差", "一般", "较好", "很好"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { level in
                Button {
                    mood = mood == level ? nil : level
                } label: {
                    VStack(spacing: 3) {
                        Text(emojis[level])
                            .font(.system(size: 22))
                            .opacity(mood == nil || mood == level ? 1 : 0.35)
                        Text(labels[level])
                            .font(.system(size: 9))
                            .foregroundColor(mood == level ? .blue : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(mood == level ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}
