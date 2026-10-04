import SwiftUI

struct DayColumnView: View {
    let dateStr: String
    let entries: [TimeEntry]
    let columnWidth: CGFloat
    let onTap: (Int, Int) -> Void
    let onEditEntry: (TimeEntry) -> Void

    @State private var dragStart: Int?
    @State private var dragEnd: Int?
    @State private var isDragging = false

    private let snap = Constants.snapMinutes
    private var isToday: Bool { dateStr == Date.todayString() }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Subtle today highlight
            if isToday {
                Color.red.opacity(0.04)
            }

            // Tap / long-press + drag background
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: 0.4)
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onChanged { value in
                            switch value {
                            case .second(true, let drag?):
                                let startMin = yToMinutes(drag.startLocation.y)
                                let currentMin = yToMinutes(drag.location.y)
                                if dragStart == nil {
                                    dragStart = startMin.flooredToSnap()
                                    isDragging = true
                                }
                                dragEnd = max(currentMin, (dragStart ?? 0) + snap).snapped()
                            default:
                                break
                            }
                        }
                        .onEnded { value in
                            if case .second(true, let drag?) = value {
                                let start = dragStart ?? yToMinutes(drag.startLocation.y).flooredToSnap()
                                let end   = max(yToMinutes(drag.location.y), start + snap).snapped()
                                onTap(start, end)
                            }
                            dragStart = nil; dragEnd = nil; isDragging = false
                        }
                )

            // Draft block preview during drag
            if isDragging, let s = dragStart, let e = dragEnd, e > s {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.blue, lineWidth: 1.5))
                    .frame(width: columnWidth - 4, height: CGFloat(e - s) * Constants.pxPerMinute)
                    .offset(x: 2, y: CGFloat(s) * Constants.pxPerMinute)
            }

            // Existing time blocks
            ForEach(entries) { entry in
                TimeBlockView(entry: entry, columnWidth: columnWidth)
                    .onTapGesture { onEditEntry(entry) }
            }
        }
        .frame(width: columnWidth, height: Constants.totalGridHeight)
        .clipped()
    }

    private func yToMinutes(_ y: CGFloat) -> Int {
        Int(y / Constants.pxPerMinute)
    }
}
