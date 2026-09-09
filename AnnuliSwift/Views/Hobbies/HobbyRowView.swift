import SwiftUI

struct HobbyRowView: View {
    let stat: HobbyStats
    let isTimerActive: Bool
    let onStartTimer: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: stat.color))
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(stat.displayLabel)
                    .font(.system(size: 15))
                Text(totalTimeLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Timer button
            Button {
                onStartTimer()
            } label: {
                Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle")
                    .font(.system(size: 22))
                    .foregroundColor(isTimerActive ? .red : Color(hex: stat.color))
            }
            .buttonStyle(.plain)

            // Edit button
            Button {
                onEdit()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private var totalTimeLabel: String {
        let mins = stat.totalMinutes
        if mins == 0 { return "暂无记录" }
        let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
