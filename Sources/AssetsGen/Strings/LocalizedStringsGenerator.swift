import Foundation

public struct LocalizedStringsGenerator {
	public let name: String
	public let langs: Set<LocalizedLanguageKey>
	public let strings: [LocalizedString]

	public init?(name: String = "LocalizedStrings", inputPath: String) {
		guard
			let strings: [LocalizedString] = FileUtils.value(atPath: inputPath)
		else { return nil }
		let langs = strings
			.flatMap { $0.values.keys }
			.reduce(into: Set<LocalizedLanguageKey>()) { $0.insert($1) }
			.filter { !$0.isSpecific }

		self.name = name
		self.langs = langs
		self.strings = strings
	}

	public func localized(for lang: LocalizedLanguageKey) -> [LocalizedStringContent] {
		strings
			.compactMap { $0.localizable(lang: lang) }
	}

	public func localizedContent(for lang: LocalizedLanguageKey) -> String {
		localized(for: lang)
			.map { $0.localizedContent }
			.joined(separator: "\n\n")
	}

	public func localizedTranslation(from source: [LocalizedStringContent]) -> String {
		let contents = source
			.map { $0.translationContent }
			.joined(separator: "\n\n")
		let html = String(
			format: #"""
			<!DOCTYPE html>
			<html>
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
				<meta http-equiv="Content-Style-Type" content="text/css">
				<title></title>
				<style type="text/css">
					p.key {background-color: #878787; font-size: 8px}
				</style>
			</head>
			<body>
			%@
			</body>
			</html>
			"""#,
			contents
		)
		return html
	}

	public func xml(for lang: LocalizedLanguageKey) -> XMLDocument {
		let root = XMLElement(name: "resources")
		let xml = XMLDocument(rootElement: root)
		strings.compactMap { $0.xml(lang: lang) }.forEach(root.addChild)
		return xml
	}

	public var swiftCode: LocalizedStringSwiftCode {
		let swiftCodes = strings
			.map { $0.swiftCode }
			.joined(separator: "\n\n")
		let swiftCode = """
		import Foundation
		import ZSWTaggedStringSwift
		
		public enum \(name) {
		\(swiftCodes)
		}
		"""
		return swiftCode
	}

	public func generate(at outputPath: String) {
		langs.forEach { lang in
			let content = localizedContent(for: lang)
			let fileName = "\(lang.langValue).lproj/Localizable.strings"
			FileUtils.save(contents: content, inPath: "\(outputPath)/\(fileName)")
		}

		let content = swiftCode
		let fileName = FileUtils.swiftFileName(from: name)
		FileUtils.save(contents: content, inPath: "\(outputPath)/\(fileName)")
	}

	public func xmlDocument(at outputPath: String) {
		langs.forEach { lang in
			let content = xml(for: lang)
			let fileName = "res/\("values" - lang.langValue)/strings.xml"
			let contents = content.xmlString(options: .nodePrettyPrint).trimmingCharacters(in: .whitespacesAndNewlines)
			FileUtils.save(contents: contents, inPath: "\(outputPath)/\(fileName)")
		}
	}

	public func generateTranslationSource(
		basedOn sourceLang: LocalizedLanguageKey,
		targeting targetLang: LocalizedLanguageKey? = nil,
		outputPath: String
	) {
		let sourceContents = localized(for: sourceLang)
		let targetContents: [LocalizedStringContent]
		if let targetLang = targetLang {
			targetContents = localized(for: targetLang)
		} else {
			targetContents = []
		}
		let targetKeys = targetContents.map { $0.key }
		let filteredSource = sourceContents.filter { !targetKeys.contains($0.key) }
		guard !filteredSource.isEmpty else { return }
		let content = localizedTranslation(from: filteredSource)
		let fileName = "translation-base-\(sourceLang.langValue)\("-targeted" - (targetLang?.langValue ?? "any")).html"
		FileUtils.save(contents: content, inPath: "\(outputPath)/\(fileName)")
	}

	public func generateTranslationSources(
		basedOn sourceLang: LocalizedLanguageKey,
		outputPath: String
	) {
		generateTranslationSource(
			basedOn: sourceLang,
			outputPath: outputPath
		)
		langs.filter { $0 != sourceLang }.forEach {
			generateTranslationSource(
				basedOn: sourceLang,
				targeting: $0,
				outputPath: outputPath
			)
		}
	}
}
