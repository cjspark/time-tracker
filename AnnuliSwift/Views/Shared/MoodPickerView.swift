import SwiftUI

struct MoodPickerView: View {
    @Binding var mood: Int?

    private let labels = ["", "很充实", "充实", "一般", "倦怠", "摸鱼"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { level in
                Button {
                    mood = mood == level ? nil : level
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: moodIcon(level))
                            .font(.system(size: 20))
                            .foregroundColor(mood == level ? .blue : .secondary)
                        Text(labels[level])
                            .font(.system(size: 9))
                            .foregroundColor(mood == level ? .blue : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func moodIcon(_ level: Int) -> String {
        switch level {
        case 1: return "face.smiling.inverse"
        case 2: return "face.smiling"
        case 3: return "face.dashed"
        case 4: return "face.dashed.fill"
        default: return "zzz"
        }
    }
}
