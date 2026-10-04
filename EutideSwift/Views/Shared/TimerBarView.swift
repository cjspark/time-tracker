import SwiftUI

// Global timer bar that floats above the tab bar
struct TimerBarView: View {
    @EnvironmentObject var timer: TimerViewModel
    @State private var showStopConfirm = false

    var body: some View {
        if timer.isRunning, let hobby = timer.activeHobby {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: timer.activeColor))
                    .frame(width: 10, height: 10)

                Text(hobby)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Text(timer.formattedElapsed)
                    .font(.system(size: 14, weight: .medium).monospacedDigit())
                    .foregroundColor(.primary)

                // Stop with save
                Button {
                    Task { await timer.stop(save: true) }
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }

                // Discard
                Button {
                    showStopConfirm = true
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color(.separator)), alignment: .top)
            .confirmationDialog("丢弃计时？", isPresented: $showStopConfirm, titleVisibility: .visible) {
                Button("丢弃", role: .destructive) {
                    Task { await timer.stop(save: false) }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
