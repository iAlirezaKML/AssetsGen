import DeepDiff
import Foundation

class StringsSource: Codable {
	class StringItem: Codable {
		enum StringType: String, Codable {
			case single
			case attributed
			case array

			func swiftCode(
				name: String,
				key: String,
				tableName: String = "Localizable.strings",
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
							tableName: tableName,
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

		struct Content {
			let lang: LanguageKey
			let comment: String
			let key: String
			let value: String

			var localizedContent: String {
				String(
					format: "/* %@ */\n\"%@\" = \"%@\";",
					comment, key, value.unescapedNewLine
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
		
		func resetValues(to value: Value, for key: LanguageKey) {
			_values = [:]
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

		func swiftCode(tableName: String) -> SwiftCode {
			type.swiftCode(
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
			.flatMap { $0.values.keys }
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
			.map { $0.localizedContent }
			.joined(separator: "\n\n")
	}

	func xml(for lang: LanguageKey) -> XMLDocument {
		let root = XMLElement(name: "resources")
		let xml = XMLDocument(rootElement: root)
		strings.compactMap { $0.xml(lang: lang) }.forEach(root.addChild)
		return xml
	}

	func swiftCode(for name: String) -> SwiftCode {
		let swiftCodes = strings
			.flatMap { $0.swiftCode(tableName: fileName) + [.newline] }
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

	func generateSwiftCode(at outputPath: String) {
		guard let codeName = codeName else { return }
		FileUtils.save(
			contents: swiftCode(for: codeName).raw,
			inPath: outputPath / FileUtils.swiftFileName(from: fileName)
		)
	}

	func generateXMLFile(at outputPath: String, baseLang: LanguageKey) {
		langs.forEach { lang in
			let content = xml(for: lang)
			let langKey = lang == baseLang ? "" : lang.langValue
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
		let sourceKeys = sourceContents.map { $0.key }
		let targetKeys = targetContents.map { $0.key }

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
