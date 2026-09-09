import SwiftUI

struct HobbyRowView: View {
    let stat: HobbyStats
    let isInactive: Bool
    let isTimerActive: Bool
    let onStartTimer: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: stat.color).opacity(isInactive ? 0.3 : 1))
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(stat.displayLabel)
                        .font(.system(size: 15))
                        .foregroundColor(isInactive ? .secondary : .primary)
                    if isInactive {
                        Text("已封存")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                Text(totalTimeLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isInactive {
                Button {
                    onStartTimer()
                } label: {
                    Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle")
                        .font(.system(size: 22))
                        .foregroundColor(isTimerActive ? .red : Color(hex: stat.color))
                }
                .buttonStyle(.plain)
            }

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
        .opacity(isInactive ? 0.7 : 1)
    }

    private var totalTimeLabel: String {
        let mins = stat.totalMinutes
        if mins == 0 { return "暂无记录" }
        let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
