import SwiftUI

struct TimeBlockView: View {
    let entry: TimeEntry
    let columnWidth: CGFloat

    private var opacity: Double { Constants.moodOpacity(entry.mood) }
    private var blockColor: Color { Color(hex: entry.color) }
    private var textColor: Color { opacity > 0.5 ? .white : Color(hex: entry.color) }

    private var top: CGFloat    { CGFloat(entry.startMinutes) * Constants.pxPerMinute }
    private var height: CGFloat { max(CGFloat(entry.durationMinutes) * Constants.pxPerMinute, 18) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(blockColor.opacity(opacity))

            if height >= 24 {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.hobby)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                    if height >= 40 {
                        Text(timeRange)
                            .font(.system(size: 10))
                            .foregroundColor(textColor.opacity(0.85))
                    }
                }
                .padding(.horizontal, 4)
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
