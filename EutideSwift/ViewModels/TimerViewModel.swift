import SwiftUI
import Combine

@MainActor
class TimerViewModel: ObservableObject {
    @Published var activeHobby: String?
    @Published var activeColor: String = "#8B5CF6"
    @Published var elapsed: Int = 0          // seconds
    @Published var isRunning: Bool = false

    private var startTime: Date?
    private var tickTask: Task<Void, Never>?

    private let defaults = UserDefaults.standard
    private let storageKey = "active_timer_v1"

    init() { restoreFromStorage() }

    var formattedElapsed: String {
        let h = elapsed / 3600
        let m = (elapsed % 3600) / 60
        let s = elapsed % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    func start(hobby: String, color: String) {
        activeHobby = hobby
        activeColor = color
        startTime = Date()
        elapsed = 0
        isRunning = true
        saveToStorage()
        beginTicking()
    }

    func stop(save: Bool) async {
        tickTask?.cancel()
        tickTask = nil

        if save, let start = startTime, elapsed >= Constants.timerMinimumSeconds {
            let startMin = Int(start.timeIntervalSince1970 / 60) * 60
            let endMin   = startMin + (elapsed / 60)
            let cal = Calendar.current
            let startDate = Date(timeIntervalSince1970: TimeInterval(startMin))
            let dateStr = startDate.localDateString()
            let startHHMM = (cal.component(.hour, from: startDate) * 60 + cal.component(.minute, from: startDate)).minutesToHHMM()
            let endHHMM   = (endMin % (24 * 60)).minutesToHHMM()

            let form = TimeEntryForm(
                date: dateStr, startTime: startHHMM, endTime: endHHMM,
                hobby: activeHobby ?? "", color: activeColor, notes: "", mood: nil
            )
            _ = try? await TimeEntryService.save(form: form)
        }

        clearStorage()
        activeHobby = nil
        elapsed = 0
        isRunning = false
    }

    // MARK: - Private

    private func beginTicking() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    elapsed += 1
                }
            }
        }
    }

    private func saveToStorage() {
        let dict: [String: Any] = [
            "hobby": activeHobby ?? "",
            "color": activeColor,
            "startTime": startTime?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        ]
        defaults.set(dict, forKey: storageKey)
    }

    private func restoreFromStorage() {
        guard let dict = defaults.dictionary(forKey: storageKey),
              let hobby = dict["hobby"] as? String, !hobby.isEmpty,
              let color = dict["color"] as? String,
              let ts    = dict["startTime"] as? TimeInterval else { return }
        activeHobby = hobby
        activeColor = color
        startTime   = Date(timeIntervalSince1970: ts)
        elapsed     = Int(Date().timeIntervalSince(startTime!))
        isRunning   = true
        beginTicking()
    }

    private func clearStorage() {
        defaults.removeObject(forKey: storageKey)
    }
}
