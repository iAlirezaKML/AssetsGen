import Foundation

enum OS: String, Codable {
	case iOS = "ios"
	case android
}

enum LanguageKey: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
	case raw(_ lang: String)
	case specific(_ lang: String, os: OS)

	private static func _make(from string: String) -> Self {
		let splitted = string.split(separator: ".").map(String.init)
		if let lang = splitted.first,
			let osRaw = splitted.last,
			let os = OS(rawValue: osRaw) {
			return .specific(lang, os: os)
		} else {
			return .raw(string)
		}
	}

	init?(rawValue: String) {
		self = Self._make(from: rawValue)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)
		self = Self._make(from: value)
	}

	init(stringLiteral value: String) {
		self = Self._make(from: value)
	}

	var rawValue: String {
		switch self {
		case let .raw(lang):
			return lang
		case let .specific(lang, os):
			return "\(lang).\(os.rawValue)"
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}

	var langValue: String {
		switch self {
		case let .raw(lang):
			return lang
		case let .specific(lang, _):
			return lang
		}
	}

	var isSpecific: Bool {
		switch self {
		case .raw:
			return false
		case .specific:
			return true
		}
	}

	func specific(for os: OS) -> Self {
		.specific(langValue, os: os)
	}

	var hashValue: Int {
		rawValue.hashValue
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}
