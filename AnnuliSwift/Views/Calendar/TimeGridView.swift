import SwiftUI

struct TimeGridView: View {
    @ObservedObject var vm: CalendarViewModel

    private let hourLabelWidth: CGFloat = 44
    private let columnMinWidth: CGFloat = 80

    var body: some View {
        GeometryReader { geo in
            let colCount  = vm.displayDates.count
            let colWidth  = max(columnMinWidth, (geo.size.width - hourLabelWidth) / CGFloat(colCount))

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid lines + labels
                        HourRulerView(totalWidth: geo.size.width)

                        // Day columns
                        HStack(spacing: 0) {
                            Spacer().frame(width: hourLabelWidth)
                            ForEach(vm.displayDates, id: \.self) { dateStr in
                                DayColumnView(
                                    dateStr: dateStr,
                                    entries: vm.entries(for: dateStr),
                                    columnWidth: colWidth,
                                    onTap: { startMin, endMin in
                                        vm.openCreate(date: dateStr, startMin: startMin, endMin: endMin)
                                    },
                                    onEditEntry: { vm.openEdit($0) }
                                )
                                .frame(width: colWidth)
                            }
                        }
                    }
                    .frame(height: Constants.totalGridHeight)
                    .id("grid")
                }
                .onAppear {
                    // Scroll to current time on appear
                    let mins = Calendar.current.component(.hour, from: Date()) * 60
                        + Calendar.current.component(.minute, from: Date())
                    let offsetY = CGFloat(mins) * Constants.pxPerMinute - geo.size.height / 2
                    proxy.scrollTo("grid", anchor: UnitPoint(x: 0, y: max(0, offsetY) / Constants.totalGridHeight))
                }
            }
        }
    }
}

// MARK: - Hour ruler

struct HourRulerView: View {
    let totalWidth: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<25) { hour in
                let y = CGFloat(hour * 60) * Constants.pxPerMinute
                HStack(spacing: 0) {
                    Text(hour < 24 ? String(format: "%02d:00", hour) : "")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 44, alignment: .trailing)
                        .padding(.trailing, 4)
                    Rectangle()
                        .fill(Color(.separator).opacity(0.4))
                        .frame(height: 0.5)
                }
                .frame(width: totalWidth)
                .offset(y: y - 6)
            }
        }
        .frame(width: totalWidth, height: Constants.totalGridHeight)
    }
}
