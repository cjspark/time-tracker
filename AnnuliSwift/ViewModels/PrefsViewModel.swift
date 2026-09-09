import SwiftUI
import Combine

// Global prefs cache — shared via EnvironmentObject
@MainActor
class PrefsViewModel: ObservableObject {
    static let shared = PrefsViewModel()

    @Published var customCategories: [String]       = []
    @Published var customHobbies: [HobbyResolver.CustomHobby] = []
    @Published var hiddenHobbies: [String]          = []
    @Published var hiddenCategories: [String]       = []
    @Published var catRenames: [String: String]     = [:]
    @Published var colorOverrides: [String: String] = [:]
    @Published var labelRenames: [String: String]   = [:]
    @Published var inactiveHobbies: [String]        = []
    @Published var catOrder: [String]               = []
    @Published var timeCategoryMap: [String: String] = [:]

    private var svc: PrefsService { PrefsService.shared }

    func load() async {
        async let cc  = svc.get(.hobbyCustomCategories, as: [String].self,              fallback: [])
        async let ch  = svc.get(.hobbyCustomHobbies,   as: [HobbyResolver.CustomHobby].self, fallback: [])
        async let hh  = svc.get(.hobbyHidden,          as: [String].self,              fallback: [])
        async let hc  = svc.get(.hobbyHiddenCategories,as: [String].self,              fallback: [])
        async let cr  = svc.get(.hobbyCatRenames,      as: [String: String].self,      fallback: [:])
        async let co  = svc.get(.hobbyColorOverrides,  as: [String: String].self,      fallback: [:])
        async let lr  = svc.get(.hobbyLabelRenames,    as: [String: String].self,      fallback: [:])
        async let ia  = svc.get(.hobbyInactive,        as: [String].self,              fallback: [])
        async let ord = svc.get(.hobbyCatOrder,        as: [String].self,              fallback: [])
        async let tc  = svc.get(.hobbyTimeCategory,    as: [String: String].self,      fallback: [:])

        let (a, b, c, d, e, f, g, h, i, j) = await (cc, ch, hh, hc, cr, co, lr, ia, ord, tc)
        customCategories = a; customHobbies = b; hiddenHobbies = c; hiddenCategories = d
        catRenames = e; colorOverrides = f; labelRenames = g; inactiveHobbies = h
        catOrder = i; timeCategoryMap = j
    }

    // Resolved hobbies
    var resolvedHobbies: [HobbyItem] {
        HobbyResolver.resolve(
            customHobbies: customHobbies, hidden: hiddenHobbies, inactive: inactiveHobbies,
            colorOverrides: colorOverrides, labelRenames: labelRenames, timeCategoryMap: timeCategoryMap
        )
    }

    // Ordered categories (built-in + custom, respecting catOrder)
    var orderedCategories: [String] {
        var all = Constants.builtInCategories + customCategories
        all = all.filter { !hiddenCategories.contains($0) }
        if !catOrder.isEmpty {
            all.sort { catOrder.firstIndex(of: $0) ?? 999 < catOrder.firstIndex(of: $1) ?? 999 }
        }
        return all
    }

    func displayName(for category: String) -> String {
        catRenames[category] ?? category
    }

    // Setters
    func hide(hobby: String) async {
        hiddenHobbies.append(hobby)
        await svc.set(.hobbyHidden, value: hiddenHobbies)
    }

    func unhide(hobby: String) async {
        hiddenHobbies.removeAll { $0 == hobby }
        await svc.set(.hobbyHidden, value: hiddenHobbies)
    }

    func setColorOverride(_ color: String, for hobby: String) async {
        colorOverrides[hobby] = color
        await svc.set(.hobbyColorOverrides, value: colorOverrides)
    }

    func setLabelRename(_ name: String, for hobby: String) async {
        labelRenames[hobby] = name
        await svc.set(.hobbyLabelRenames, value: labelRenames)
    }

    func setTimeCategory(_ cat: String, for hobby: String) async {
        timeCategoryMap[hobby] = cat
        await svc.set(.hobbyTimeCategory, value: timeCategoryMap)
    }

    func addCustomHobby(label: String, color: String) async {
        customHobbies.append(.init(label: label, color: color))
        await svc.set(.hobbyCustomHobbies, value: customHobbies)
    }

    func addCustomCategory(_ name: String) async {
        customCategories.append(name)
        await svc.set(.hobbyCustomCategories, value: customCategories)
    }
}
