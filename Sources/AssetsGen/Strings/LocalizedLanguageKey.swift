import Foundation

public enum OS: String, Codable {
	case iOS = "ios"
	case android
}

public enum LocalizedLanguageKey: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
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

	public init?(rawValue: String) {
		self = Self._make(from: rawValue)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)
		self = Self._make(from: value)
	}

	public init(stringLiteral value: String) {
		self = Self._make(from: value)
	}

	public var rawValue: String {
		switch self {
		case let .raw(lang):
			return lang
		case let .specific(lang, os):
			return "\(lang).\(os.rawValue)"
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}

	public var langValue: String {
		switch self {
		case let .raw(lang):
			return lang
		case let .specific(lang, _):
			return lang
		}
	}

	public var isSpecific: Bool {
		switch self {
		case .raw:
			return false
		case .specific:
			return true
		}
	}

	public func specific(for os: OS) -> Self {
		.specific(langValue, os: os)
	}

	public var hashValue: Int {
		rawValue.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}
