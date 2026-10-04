import Foundation

struct UserPreference: Codable {
    var userId: UUID
    var key: String
    var value: PreferenceValue

    enum CodingKeys: String, CodingKey {
        case key, value
        case userId = "user_id"
    }
}

// Flexible JSON value using Codable
enum PreferenceValue: Codable {
    case array([String])
    case objectArray([[String: String]])
    case dictionary([String: String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([String].self) {
            self = .array(arr)
        } else if let objArr = try? container.decode([[String: String]].self) {
            self = .objectArray(objArr)
        } else if let dict = try? container.decode([String: String].self) {
            self = .dictionary(dict)
        } else {
            self = .array([])
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let v):       try container.encode(v)
        case .objectArray(let v): try container.encode(v)
        case .dictionary(let v):  try container.encode(v)
        }
    }
}
