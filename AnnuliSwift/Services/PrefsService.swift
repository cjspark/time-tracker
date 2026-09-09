import Foundation
import Supabase

// PrefsService: read/write user_preferences table with UserDefaults mirror
actor PrefsService {
    static let shared = PrefsService()
    private let defaults = UserDefaults.standard

    // MARK: - Generic read/write

    func get<T: Codable>(_ key: PrefsKey, as type: T.Type, fallback: T) async -> T {
        // Try local cache first (fast path)
        if let cached = localGet(key, as: type) { return cached }
        // Fetch from Supabase
        guard let userId = AuthService.currentUserId else { return fallback }
        do {
            let rows: [UserPreferenceRaw] = try await supabase
                .from("user_preferences")
                .select()
                .eq("user_id", value: userId)
                .eq("key", value: key.rawValue)
                .execute()
                .value
            if let row = rows.first, let decoded = try? JSONDecoder().decode(type, from: row.valueData) {
                localSet(key, value: decoded)
                return decoded
            }
        } catch {}
        return fallback
    }

    func set<T: Codable>(_ key: PrefsKey, value: T) async {
        localSet(key, value: value)
        guard let userId = AuthService.currentUserId,
              let data = try? JSONEncoder().encode(value),
              let json = try? JSONSerialization.jsonObject(with: data) else { return }

        struct Row: Encodable {
            let userId: UUID; let key: String; let value: AnyEncodable
            enum CodingKeys: String, CodingKey { case key, value; case userId = "user_id" }
        }
        _ = try? await supabase
            .from("user_preferences")
            .upsert(["user_id": userId.uuidString, "key": key.rawValue, "value": json],
                    onConflict: "user_id,key")
            .execute()
    }

    // MARK: - Local cache helpers

    private func localGet<T: Codable>(_ key: PrefsKey, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: "pref_\(key.rawValue)") else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func localSet<T: Codable>(_ key: PrefsKey, value: T) {
        let data = try? JSONEncoder().encode(value)
        defaults.set(data, forKey: "pref_\(key.rawValue)")
    }
}

// MARK: - Preference keys

enum PrefsKey: String {
    case hobbyCustomCategories   = "hobby_custom_categories"
    case hobbyCustomHobbies      = "hobby_custom_hobbies"
    case hobbyHidden             = "hobby_hidden"
    case hobbyHiddenCategories   = "hobby_hidden_categories"
    case hobbyCatRenames         = "hobby_cat_renames"
    case hobbyColorOverrides     = "hobby_color_overrides"
    case hobbyLabelRenames       = "hobby_label_renames"
    case hobbyInactive           = "hobby_inactive"
    case hobbyCatOrder           = "hobby_cat_order"
    case hobbyTimeCategory       = "hobby_time_category"
}

// MARK: - Internal DB row

private struct UserPreferenceRaw: Decodable {
    let key: String
    let valueData: Data

    enum CodingKeys: String, CodingKey { case key, value }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        // Re-encode the raw JSON back to Data for generic decoding
        let raw = try container.decode(AnyDecodable.self, forKey: .value)
        self.valueData = (try? JSONEncoder().encode(raw)) ?? Data()
    }
}

// MARK: - AnyEncodable / AnyDecodable helpers

struct AnyEncodable: Encodable {
    let value: Any
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as [String]:          try container.encode(v)
        case let v as [String: String]:  try container.encode(v)
        case let v as [[String: String]]:try container.encode(v)
        case let v as String:            try container.encode(v)
        case let v as Int:               try container.encode(v)
        case let v as Double:            try container.encode(v)
        case let v as Bool:              try container.encode(v)
        default: try container.encodeNil()
        }
    }
}

struct AnyDecodable: Decodable, Encodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode([String].self)             { value = v; return }
        if let v = try? c.decode([String: String].self)     { value = v; return }
        if let v = try? c.decode([[String: String]].self)   { value = v; return }
        if let v = try? c.decode(String.self)               { value = v; return }
        if let v = try? c.decode(Int.self)                  { value = v; return }
        if let v = try? c.decode(Double.self)               { value = v; return }
        if let v = try? c.decode(Bool.self)                 { value = v; return }
        value = ""
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as [String]:          try c.encode(v)
        case let v as [String: String]:  try c.encode(v)
        case let v as [[String: String]]:try c.encode(v)
        case let v as String:            try c.encode(v)
        case let v as Int:               try c.encode(v)
        case let v as Double:            try c.encode(v)
        case let v as Bool:              try c.encode(v)
        default: try c.encodeNil()
        }
    }
}
