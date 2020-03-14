import Foundation

struct StringsGenerator {
	let name: String
	let langs: Set<LanguageKey>
	let strings: [LocalizedString]

	init?(name: String = "LocalizedStrings", inputPath: String) {
		guard
			let strings: [LocalizedString] = FileUtils.value(atPath: inputPath)
		else { return nil }
		let langs = strings
			.flatMap { $0.values.keys }
			.reduce(into: Set<LanguageKey>()) { $0.insert($1) }
			.filter { !$0.isSpecific }

		self.name = name
		self.langs = langs
		self.strings = strings
	}

	func localized(for lang: LanguageKey) -> [LocalizedString.Content] {
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

	var swiftCode: SwiftCode {
		let swiftCodes = strings
			.flatMap { $0.swiftCode + [.newline] }
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

	func generate(at outputPath: String) {
		langs.forEach { lang in
			let content = localizedContent(for: lang)
			let fileName = "\(lang.langValue).lproj/Localizable.strings"
			FileUtils.save(contents: content, inPath: "\(outputPath)/\(fileName)")
		}

		let content = swiftCode.raw
		let fileName = FileUtils.swiftFileName(from: name)
		FileUtils.save(contents: content, inPath: "\(outputPath)/\(fileName)")
	}

	func xmlDocument(at outputPath: String) {
		langs.forEach { lang in
			let content = xml(for: lang)
			let fileName = "res/\("values" - lang.langValue)/strings.xml"
			let contents = content.xmlString(options: .nodePrettyPrint).trimmingCharacters(in: .whitespacesAndNewlines)
			FileUtils.save(contents: contents, inPath: "\(outputPath)/\(fileName)")
		}
	}
}
