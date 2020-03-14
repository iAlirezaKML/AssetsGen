import Foundation

class LocalizedString: Codable {
	enum StringType: String, Codable {
		case single
		case attributed
		case array

		func swiftCode(
			name: String,
			key: String,
			comment: String?,
			args: String?,
			vars: String?
		) -> SwiftCode {
			let comment = comment ?? ""
			let args = args ?? ""
			let vars = vars ?? ""
			switch self {
			case .single:
				return [
					.funcReturnString(
						name: name,
						key: key,
						comment: comment,
						args: args,
						vars: vars
					),
				]
			case .attributed:
				return [
					.funcReturnAttributedString(
						name: name,
						key: key,
						comment: comment,
						args: args,
						vars: vars
					),
				]
			case .array:
				return [
					.funcReturnStringArray(
						name: name,
						key: key,
						comment: comment
					),
				]
			}
		}
	}

	struct Variable: Codable {
		let name: String
		let type: String
	}

	enum Value: Codable {
		case single(String)
		case array([String])

		init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			do {
				let value = try container.decode(String.self)
				self = .single(value)
			} catch {
				let value = try container.decode([String].self)
				self = .array(value)
			}
		}

		func encode(to encoder: Encoder) throws {
			switch self {
			case let .single(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .array(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			}
		}

		init(_ string: String) {
			if string.starts(with: "<item>") {
				let strings = string
					.replacingOccurrences(of: "<item>", with: "")
					.replacingOccurrences(of: "</item>", with: "~")
					.split(separator: "~")
					.map(String.init)
				self = .array(strings)
			} else {
				self = .single(string)
			}
		}

		var localizableValue: String {
			switch self {
			case let .single(string):
				return string.unescapedQuotes
			case let .array(strings):
				return strings
					.map { "<item>\($0.unescapedQuotes)</item>" }
					.joined(separator: ",")
			}
		}

		func xml(type: StringType) -> XMLElement {
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

	struct Content {
		let lang: LanguageKey
		let comment: String
		let key: String
		let value: String

		var localizedContent: String {
			String(
				format: "/* %@ */\n\"%@\" = \"%@\"",
				comment, key, value
			)
		}
	}

	let key: String
	let comment: String?
	private let _type: StringType?
	let variables: [Variable]?
	private(set) var _values: [String: Value]

	var type: StringType {
		_type ?? .single
	}

	private(set) lazy var values = _computeValues()

	enum CodingKeys: String, CodingKey {
		case key
		case comment
		case _type = "type"
		case variables
		case _values = "values"
	}

	init(
		key: String,
		comment: String?,
		type: StringType,
		variables: [Variable]?,
		values: [String: Value]
	) {
		self.key = key
		self.comment = comment
		_type = type
		self.variables = variables
		_values = values
	}

	private func _computeValues() -> [LanguageKey: Value] {
		let array = _values.map {
			(LanguageKey(rawValue: $0) ?? .raw($0), $1)
		}
		return Dictionary(uniqueKeysWithValues: array)
	}

	func set(_ value: String, for key: LanguageKey) {
		set(Value(value), for: key)
	}

	func set(_ value: Value, for key: LanguageKey) {
		_values[key.langValue] = value
		values = _computeValues()
	}

	func value(for lang: LanguageKey, with osPriority: OS) -> Value? {
		values[lang.specific(for: osPriority)] ??
			values[lang]
	}

	func localizable(lang: LanguageKey) -> Content? {
		guard let value = value(for: lang, with: .iOS) else { return nil }
		return Content(
			lang: lang,
			comment: comment ?? "No comments",
			key: key,
			value: value.localizableValue
		)
	}

	var swiftCode: SwiftCode {
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

	func xml(lang: LanguageKey) -> XMLElement? {
		guard let value = value(for: lang, with: .android) else { return nil }
		let node = value.xml(type: type)
		node.setAttributesWith(["name": key])
		return node
	}
}
