import Foundation

public typealias LocalizedLanguageKey = String
public typealias LocalizedStringContent = String
public typealias LocalizedStringSwiftCode = String

public struct LocalizedString: Codable {
	public enum StringType: String, Codable {
		case single
		case attributed
		case array

		public func swiftCode(
			name: String,
			key: String,
			comment: String?,
			args: String?,
			vars: String?
		) -> LocalizedStringSwiftCode {
			let comment = comment ?? ""
			let args = args ?? ""
			let vars = vars ?? ""
			switch self {
			case .single:
				return """
				public static func \(name)(\(args)) -> String {
				return String(
				format: NSLocalizedString(
				"\(key)",
				comment: "\(comment)"
				)\(vars)
				)
				}
				"""
			case .attributed:
				return """
				public static func \(name)(\(args)) -> NSAttributedString? {
				return try? ZSWTaggedString(
				format: NSLocalizedString(
				"\(key)",
				comment: "\(comment)"
				)\(vars)
				).attributedString()
				}
				"""
			case .array:
				return """
				public static func \(name)() -> [String] {
				return parseItems(
				NSLocalizedString(
				"\(key)",
				comment: "\(comment)"
				)
				)
				}
				"""
			}
		}
	}

	public struct Variable: Codable {
		public let name: String
		public let type: String
	}

	public enum Value: Codable {
		case single(String)
		case array([String])

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			do {
				let value = try container.decode(String.self)
				self = .single(value)
			} catch {
				let value = try container.decode([String].self)
				self = .array(value)
			}
		}

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .single(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .array(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			}
		}

		public var localizable: LocalizedStringContent {
			switch self {
			case let .single(string):
				return string.unescapedQuotes
			case let .array(strings):
				return strings
					.map { "<item>\($0.unescapedQuotes)</item>" }
					.joined(separator: ",")
			}
		}
	}

	public let key: String
	public let comment: String?
	private let _type: StringType?
	public let variables: [Variable]?
	public let values: [LocalizedLanguageKey: Value]

	public var type: StringType {
		_type ?? .single
	}

	enum CodingKeys: String, CodingKey {
		case key
		case comment
		case _type = "type"
		case variables
		case values
	}

	public func localizable(lang: LocalizedLanguageKey) -> LocalizedStringContent? {
		guard let value = values[lang] else { return nil }
		let comment = self.comment ?? "No comments"
		let content = value.localizable
		return String(
			format: "/* %@ */\n\"%@\" = \"%@\"",
			comment, key, content
		)
	}

	public var swiftCode: LocalizedStringSwiftCode {
		type.swiftCode(
			name: key.camelCased,
			key: key.unescapedQuotes,
			comment: comment?.unescapedQuotes,
			args: variables?
				.map { "\($0.name): \($0.type)" }
				.joined(separator: ","),
			vars: variables?
				.map { ",\n\($0.name)" }
				.joined()
		)
	}
}
