import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    enum ViewMode: String, CaseIterable {
        case day = "日", twoDay = "两日", week = "周"
    }

    @Published var viewMode: ViewMode = .day
    @Published var anchorDate: Date = Date()
    @Published var entries: [TimeEntry] = []
    @Published var isLoading = false

    // Sheet state
    @Published var showEntrySheet = false
    @Published var editingEntry: TimeEntry?
    @Published var draftForm: TimeEntryForm = .empty(date: Date.todayString())

    // Drag-to-create state
    @Published var draftBlock: DraftBlock?

    struct DraftBlock {
        var date: String
        var startMin: Int
        var endMin: Int
    }

    var displayDates: [String] {
        switch viewMode {
        case .day:
            return [anchorDate.localDateString()]
        case .twoDay:
            return [anchorDate.localDateString(), anchorDate.adding(days: 1).localDateString()]
        case .week:
            return WeekCalculator.weekDateStrings(containing: anchorDate)
        }
    }

    func load() async {
        isLoading = true
        do {
            entries = try await TimeEntryService.fetch(dates: displayDates)
        } catch {}
        isLoading = false
    }

    func navigate(by days: Int) async {
        anchorDate = anchorDate.adding(days: days)
        await load()
    }

    func goToDate(_ date: Date) async {
        anchorDate = date
        await load()
    }

    func openCreate(date: String, startMin: Int, endMin: Int) {
        draftForm = TimeEntryForm(date: date, startTime: startMin.minutesToHHMM(),
                                  endTime: endMin.minutesToHHMM(), hobby: "", color: "#8B5CF6",
                                  notes: "", mood: nil)
        editingEntry = nil
        showEntrySheet = true
    }

    func openEdit(_ entry: TimeEntry) {
        draftForm = TimeEntryForm(
            date: entry.date,
            startTime: String(entry.startTime.prefix(5)),
            endTime:   String(entry.endTime.prefix(5)),
            hobby: entry.hobby, color: entry.color,
            notes: entry.notes ?? "", mood: entry.mood
        )
        editingEntry = entry
        showEntrySheet = true
    }

    func saveEntry() async {
        do {
            let saved = try await TimeEntryService.save(form: draftForm, id: editingEntry?.id)
            if let idx = entries.firstIndex(where: { $0.id == saved.id }) {
                entries[idx] = saved
            } else {
                entries.append(saved)
                entries.sort { $0.startTime < $1.startTime }
            }
        } catch {}
        showEntrySheet = false
        editingEntry = nil
    }

    func deleteEntry(_ entry: TimeEntry) async {
        do {
            try await TimeEntryService.delete(id: entry.id)
            entries.removeAll { $0.id == entry.id }
        } catch {}
        showEntrySheet = false
        editingEntry = nil
    }

    func entries(for date: String) -> [TimeEntry] {
        entries.filter { $0.date == date }
    }
}
