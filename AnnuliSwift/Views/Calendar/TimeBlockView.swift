import SwiftUI

struct TimeBlockView: View {
    let entry: TimeEntry
    let columnWidth: CGFloat

    private var opacity: Double { Constants.moodOpacity(entry.mood) }
    private var blockColor: Color { Color(hex: entry.color) }

    private var top: CGFloat    { CGFloat(entry.startMinutes) * Constants.pxPerMinute }
    private var height: CGFloat { max(CGFloat(entry.durationMinutes) * Constants.pxPerMinute, 18) }

    // Show notes if present, otherwise hobby name
    private var displayText: String {
        let notes = entry.notes ?? ""
        return notes.isEmpty ? entry.hobby : notes
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background fill (lighter)
            RoundedRectangle(cornerRadius: 4)
                .fill(blockColor.opacity(opacity * 0.45))

            // Left border stripe
            HStack(spacing: 0) {
                Rectangle()
                    .fill(blockColor)
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))

            if height >= 22 {
                VStack(alignment: .leading, spacing: 1) {
                    Text(displayText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(blockColor.opacity(opacity > 0.4 ? 1.0 : 0.8))
                        .lineLimit(1)
                    if height >= 40 {
                        Text(timeRange)
                            .font(.system(size: 10))
                            .foregroundColor(blockColor.opacity(0.75))
                    }
                }
                .padding(.leading, 7)
                .padding(.trailing, 3)
                .padding(.vertical, 2)
            }
        }
        .frame(width: columnWidth - 4, height: height)
        .offset(x: 2, y: top)
    }

    private var timeRange: String {
        "\(String(entry.startTime.prefix(5))) – \(String(entry.endTime.prefix(5)))"
    }
}
