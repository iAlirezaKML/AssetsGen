import DeepDiff
import Foundation

class StringsSource: Codable {
	let fileName: String
	let codeName: String?
	let strings: [StringItem]

	enum CodingKeys: String, CodingKey {
		case fileName
		case codeName
		case strings
	}

	private(set) lazy var langs = _computeLangs()

	private func _computeLangs() -> Set<LanguageKey> {
		strings
			.flatMap(\.values.keys)
			.reduce(into: Set<LanguageKey>()) { $0.insert($1) }
			.filter { !$0.isSpecific }
	}

	init(
		fileName: String,
		codeName: String?,
		strings: [StringItem]
	) {
		self.fileName = fileName
		self.codeName = codeName
		self.strings = strings
	}

	func localized(for lang: LanguageKey) -> [StringItem.Content] {
		strings
			.compactMap { $0.localizable(lang: lang) }
	}

	func localizedContent(for lang: LanguageKey) -> String {
		localized(for: lang)
			.map(\.localizedContent)
			.joined(separator: "\n\n")
	}

	func xml(for lang: LanguageKey) -> XMLDocument {
		let root = XMLElement(name: "resources")
		let xml = XMLDocument(rootElement: root)
		strings.compactMap { $0.xml(lang: lang) }.forEach(root.addChild)
		return xml
	}

	func swiftCode(for name: String, baseLang: LanguageKey) -> SwiftCode {
		let tableName = fileName.split(separator: ".").dropLast().joined(separator: ".")
		let swiftCodes = strings
			.flatMap { $0.swiftCode(tableName: tableName, baseLang: baseLang) + [.newline] }
		return [
			.import("Foundation"),
			.import("ZSWTaggedStringSwift"),
			.newline,
			.enum(
				name: name,
				content: swiftCodes
			),
		]
	}

	func generateStringsFile(at outputPath: String) {
		langs.forEach { lang in
			let content = localizedContent(for: lang)
			FileUtils.save(
				contents: content,
				inPath: outputPath / "\(lang.langValue).lproj" / fileName
			)
		}
	}

	func generateSwiftCode(at outputPath: String, baseLang: LanguageKey) {
		guard let codeName = codeName else { return }
		FileUtils.save(
			contents: swiftCode(for: codeName, baseLang: baseLang).raw,
			inPath: outputPath / FileUtils.swiftFileName(from: fileName)
		)
	}

	func generateXMLFile(at outputPath: String, baseLang: LanguageKey) {
		langs.forEach { lang in
			let content = xml(for: lang)
			var langKey = lang == baseLang ? "" : lang.langValue
			let langKeyComps = langKey.components(separatedBy: "-")
			if langKeyComps.count == 2 {
				let regionCode = "r" + langKeyComps[1]
				langKey = langKeyComps[0] + "-" + regionCode
			}
			let contents = content
				.xmlString(options: .nodePrettyPrint)
				.trimmingCharacters(in: .whitespacesAndNewlines)
			FileUtils.save(
				contents: contents,
				inPath: outputPath / fileName / "res" / ("values" - langKey) / "strings.xml"
			)
		}
	}

	func xliffFile(
		sourceLang: LanguageKey,
		targetLang: LanguageKey,
		projectName: String,
		filterExisting: Bool
	) -> XLIFF.File? {
		let sourceContents = localized(for: sourceLang)
		let targetContents = localized(for: targetLang)
		let sourceKeys = sourceContents.map(\.key)
		let targetKeys = targetContents.map(\.key)

		let keys = filterExisting ?
			sourceKeys.filter { !targetKeys.contains($0) } :
			sourceKeys

		guard !keys.isEmpty else {
			return nil
		}

		return XLIFF.File(
			original: projectName / "\(sourceLang.langValue).lproj" / fileName,
			sourceLanguage: sourceLang,
			targetLanguage: targetLang,
			body: XLIFF.File.Body(
				transUnits: keys.compactMap { key in
					guard
						let source = sourceContents.first(where: { $0.key == key })
					else { return nil }
					return XLIFF.File.Body.TransUnit(
						id: key,
						source: source.value,
						target: targetContents.first(where: { $0.key == key })?.value,
						note: source.comment
					)
				}
			)
		)
	}
}

extension StringsSource {
	class StringItem: Codable {
		struct Element: Codable, Comparable {
			static func < (lhs: Self, rhs: Self) -> Bool {
				lhs.key < rhs.key
			}

			static func == (lhs: Self, rhs: Self) -> Bool {
				lhs.key == rhs.key
			}

			let key: String
			var value: Value
		}

		let key: String
		let comment: String?
		private let _type: StringType?
		let variables: [Variable]?
		private(set) var _values: [Element]

		var type: StringType {
			_type ?? .single
		}

		private(set) lazy var values = _computeValues()

		required init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			key = try container.decode(String.self, forKey: .key)
			comment = try? container.decode(String.self, forKey: .comment)
			_type = try? container.decode(StringType.self, forKey: ._type)
			variables = try? container.decode([Variable].self, forKey: .variables)
			// try the dictionary for backward compatibility
			if let values = try? container.decode([String: Value].self, forKey: ._values) {
				_values = values.map { Element(key: $0.key, value: $0.value) }
			} else {
				_values = try container.decode([Element].self, forKey: ._values)
			}
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(key, forKey: .key)
			try container.encode(comment, forKey: .comment)
			try container.encode(_type, forKey: ._type)
			try container.encode(variables, forKey: .variables)
			try container.encode(_values.sorted(by: <), forKey: ._values)
		}

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
			values: [Element]
		) {
			self.key = key
			self.comment = comment
			_type = type
			self.variables = variables
			_values = values
		}

		private func _computeValues() -> [LanguageKey: Value] {
			let array = _values.map {
				(LanguageKey(rawValue: $0.key) ?? .raw($0.key), $0.value)
			}
			return Dictionary(uniqueKeysWithValues: array)
		}

		func set(_ value: String, for key: LanguageKey) {
			set(Value(value), for: key)
		}

		func set(_ value: Value, for key: LanguageKey) {
			if let idx = _values.firstIndex(where: { $0.key == key.rawValue }) {
				_values[idx].value = value
			} else {
				_values.append(Element(key: key.rawValue, value: value))
			}
			values = _computeValues()
		}

		func resetValues(to value: Value, for key: LanguageKey) {
			_values = []
			set(value, for: key)
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

		func swiftCode(tableName: String, baseLang: LanguageKey) -> SwiftCode {
			type.swiftCode(
				preview: values[baseLang]?.localizableValue,
				name: key.swiftCamelCased,
				key: key.unescapedQuotes,
				tableName: tableName,
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
}

extension StringsSource.StringItem {
	enum StringType: String, Codable {
		case single
		case attributed
		case array

		func swiftCode(
			preview: String?,
			name: String,
			key: String,
			tableName: String = "Localizable",
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
						preview: preview,
						name: name,
						key: key,
						tableName: tableName,
						comment: comment,
						args: args,
						vars: vars
					),
				]
			case .attributed:
				return [
					.funcReturnAttributedString(
						preview: preview,
						name: name,
						key: key,
						tableName: tableName,
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
						tableName: tableName,
						comment: comment
					),
				]
			}
		}
	}
}

extension StringsSource.StringItem {
	struct Variable: Codable {
		let name: String
		let type: String
	}
}

extension StringsSource.StringItem {
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
				return decodeNumericEntities(string)
			case let .array(strings):
				return strings
					.map { "<item>\(decodeNumericEntities($0))</item>" }
					.joined(separator: ",")
			}
		}

		private func decodeNumericEntities(_ input: String) -> String {
			let nsMutableString = NSMutableString(string: input)
			CFStringTransform(nsMutableString, nil, "Any-Hex/XML10" as CFString, true)
			let str = nsMutableString as String
			return str.unescapedQuotes
		}

		func xml(type: StringType) -> XMLElement {
			switch self {
			case let .single(string):
				let element = XMLElement(name: "string")
				if type == .attributed {
					let content = XMLElement(kind: .text, options: [.nodeNeverEscapeContents, .nodePreserveAll])
					content.setStringValue(string, resolvingEntities: false)
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
}

extension StringsSource.StringItem {
	struct Content {
		let lang: LanguageKey
		let comment: String
		let key: String
		let value: String

		var localizedContent: String {
			String(
				format: "/* %@ */\n\"%@\" = \"%@\";",
				comment, key, fixingFormatSymbols(value.unescapedNewLine)
			)
		}

		private func fixingFormatSymbols(_ string: String) -> String {
			let nsrange = NSRange(string.startIndex ..< string.endIndex, in: string)
			let pattern = #"%(\d+\$)?s"# // detects <%s> or <%1$s>
			guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
			else { return string }
			var result = string
			regex.matches(in: string, options: [], range: nsrange).forEach { match in
				let range = Range(match.range, in: string)
				result = result.replacingOccurrences(of: "s", with: "@", range: range)
			}
			return result
		}
	}
}

extension Array where Element == StringsSource {
	init(inputPath: String, files: [String]) {
		self = files.compactMap { FileUtils.value(atPath: inputPath / $0) }
	}
}

extension StringsSource.StringItem: DiffAware {
	var diffId: String {
		key
	}

	static func compareContent(_ a: StringsSource.StringItem, _ b: StringsSource.StringItem) -> Bool {
		let isSameValue: Bool
		if let aValue = a.value(for: Configs.baseLang, with: Configs.os),
			let bValue = b.value(for: Configs.baseLang, with: Configs.os) {
			isSameValue = aValue.localizableValue == bValue.localizableValue
		} else {
			isSameValue = false
		}
		return isSameValue
	}
}
