import Foundation

// MARK: - Built-in data

enum Constants {
    static let pxPerMinute: CGFloat = 1.2
    static let totalGridHeight: CGFloat = 1440 * 1.2  // 1728
    static let snapMinutes = 15
    static let timerMinimumSeconds = 60

    static let builtInHobbies: [(label: String, color: String)] = [
        ("锻炼",    "#EF4444"),
        ("日语",    "#F97316"),
        ("钢琴",    "#8B5CF6"),
        ("英语",    "#3B82F6"),
        ("炒股",    "#10B981"),
        ("西语",    "#F59E0B"),
        ("写作",    "#6366F1"),
        ("书影音",  "#EC4899"),
        ("饮食管理","#14B8A6"),
    ]

    static let builtInCategories = ["工作", "输入", "输出", "健康", "投资", "瞎忙"]

    // Category → default hobbies mapping
    static let categoryDefaults: [String: [String]] = [
        "工作": [],
        "输入": ["日语", "英语", "西语", "书影音"],
        "输出": ["写作", "钢琴"],
        "健康": ["锻炼", "饮食管理"],
        "投资": ["炒股"],
        "瞎忙": [],
    ]

    // Mood opacity
    static func moodOpacity(_ mood: Int?) -> Double {
        switch mood {
        case 1: return 0.95
        case 2: return 0.75
        case 3: return 0.55
        case 4: return 0.35
        default: return 0.18
        }
    }
}
