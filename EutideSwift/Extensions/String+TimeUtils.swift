import Foundation

extension String {
    // "HH:MM:SS" or "HH:MM" → total minutes from midnight
    func timeToMinutes() -> Int {
        let parts = split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count >= 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}

extension Int {
    // total minutes → "HH:MM"
    func minutesToHHMM() -> String {
        let h = self / 60
        let m = self % 60
        return String(format: "%02d:%02d", h, m)
    }

    // Snap to nearest N-minute boundary
    func snapped(to interval: Int = Constants.snapMinutes) -> Int {
        Int(round(Double(self) / Double(interval))) * interval
    }

    func flooredToSnap(_ interval: Int = Constants.snapMinutes) -> Int {
        (self / interval) * interval
    }

    func ceiledToSnap(_ interval: Int = Constants.snapMinutes) -> Int {
        let r = self % interval
        return r == 0 ? self : self + (interval - r)
    }
}
