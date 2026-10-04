import Foundation

// Merges built-in hobbies with user custom hobbies, applying color and rename overrides.
struct HobbyResolver {
    struct CustomHobby: Codable {
        let label: String
        let color: String
    }

    static func resolve(
        customHobbies: [CustomHobby],
        hidden: [String],
        inactive: [String],
        colorOverrides: [String: String],
        labelRenames: [String: String],
        timeCategoryMap: [String: String]
    ) -> [HobbyItem] {
        var all: [(label: String, color: String)] = Constants.builtInHobbies
        for ch in customHobbies where !all.contains(where: { $0.label == ch.label }) {
            all.append((ch.label, ch.color))
        }

        let hiddenSet   = Set(hidden)
        let inactiveSet = Set(inactive)

        return all
            .filter { !hiddenSet.contains($0.label) && !inactiveSet.contains($0.label) }
            .map { item in
                let resolvedColor = resolveColor(
                    label: item.label, base: item.color,
                    colorOverrides: colorOverrides, timeCategoryMap: timeCategoryMap
                )
                return HobbyItem(
                    label: item.label,
                    displayLabel: labelRenames[item.label] ?? item.label,
                    color: resolvedColor
                )
            }
    }

    // Color priority: timeCategoryColor > colorOverride > baseColor
    static func resolveColor(
        label: String,
        base: String,
        colorOverrides: [String: String],
        timeCategoryMap: [String: String]
    ) -> String {
        if let catKey = timeCategoryMap[label], let cat = TimeCategory(rawValue: catKey) {
            return cat.hex
        }
        return colorOverrides[label] ?? base
    }
}
