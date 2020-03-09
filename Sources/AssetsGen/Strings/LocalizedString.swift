import Foundation

// public typealias LocalizedStringContent = String
public typealias LocalizedStringSwiftCode = String

public class LocalizedString: Codable {
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

		public var localizableValue: String {
			switch self {
			case let .single(string):
				return string.unescapedQuotes
			case let .array(strings):
				return strings
					.map { "<item>\($0.unescapedQuotes)</item>" }
					.joined(separator: ",")
			}
		}

		public func xml(type: StringType) -> XMLElement {
			switch self {
			case let .single(string):
				let element = XMLElement(name: "string")
				if type == .attributed {
					let content = XMLElement(kind: .text, options: [.nodeNeverEscapeContents, .nodePreserveAll])
					content.setStringValue(string, resolvingEntities: true)
					element.setChildren([content])
				} else {
					element.setStringValue(string, resolvingEntities: true)
				}
				return element
			case let .array(strings):
				let root = XMLElement(name: "string-array")
				strings.forEach { root.addChild(XMLElement(name: "item", stringValue: $0)) }
				return root
			}
		}
	}

	public let key: String
	public let comment: String?
	private let _type: StringType?
	public let variables: [Variable]?
	public let _values: [String: Value]

	public var type: StringType {
		_type ?? .single
	}

	public lazy var values: [LocalizedLanguageKey: Value] = {
		let array = _values.map {
			(LocalizedLanguageKey(rawValue: $0) ?? .raw($0), $1)
		}
		return Dictionary(uniqueKeysWithValues: array)
	}()

	enum CodingKeys: String, CodingKey {
		case key
		case comment
		case _type = "type"
		case variables
		case _values = "values"
	}

	public func value(for lang: LocalizedLanguageKey, with osPriority: OS) -> Value? {
		values[lang.specific(for: osPriority)] ??
			values[lang]
	}

	public func localizable(lang: LocalizedLanguageKey) -> LocalizedStringContent? {
		guard let value = value(for: lang, with: .iOS) else { return nil }
		return LocalizedStringContent(
			lang: lang,
			comment: comment ?? "No comments",
			key: key,
			value: value.localizableValue
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

	public func xml(lang: LocalizedLanguageKey) -> XMLElement? {
		guard let value = value(for: lang, with: .android) else { return nil }
		let node = value.xml(type: type)
		node.setAttributesWith(["name": key])
		return node
	}
}
