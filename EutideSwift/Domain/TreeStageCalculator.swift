import Foundation

struct TreeStageCalculator {
    static func stage(totalMinutes: Int) -> Int {
        let hours = Double(totalMinutes) / 60.0
        switch hours {
        case ..<2:    return 1
        case ..<8:    return 2
        case ..<25:   return 3
        case ..<60:   return 4
        default:      return 5
        }
    }

    // Fruit stage only applies at tree stage 5
    static func fruitStage(achievementCount: Int) -> String? {
        guard achievementCount > 0 else { return nil }
        switch achievementCount {
        case 1:    return "a"
        case 2...5: return "b"
        case 6...15: return "c"
        default:    return "d"
        }
    }

    // Asset name helpers
    static func treeImageName(stage: Int) -> String {
        "tree-\(stage)"   // maps to Assets "tree-1" through "tree-5"
    }

    static func fruitImageName(fruitStage: String) -> String {
        "fruit-\(fruitStage)"
    }

    static func stageProgressDescription(stage: Int, totalMinutes: Int) -> String {
        let hours = Double(totalMinutes) / 60.0
        switch stage {
        case 1: return String(format: "%.1f/2h", hours)
        case 2: return String(format: "%.1f/8h", hours)
        case 3: return String(format: "%.1f/25h", hours)
        case 4: return String(format: "%.1f/60h", hours)
        default: return String(format: "%.1fh", hours)
        }
    }

    static func stageNextThreshold(stage: Int) -> Double {
        switch stage {
        case 1: return 2
        case 2: return 8
        case 3: return 25
        case 4: return 60
        default: return 60
        }
    }
}
