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

		self.name = name
		self.langs = langs
		self.strings = strings
	}

	public func localized(for lang: LocalizedLanguageKey) -> LocalizedStringContent {
		let content = strings
			.compactMap { $0.localizable(lang: lang) }
			.joined(separator: "\n\n")
		return content
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
			let content = localized(for: lang)
			let fileName = "\(lang).lproj/Localizable.strings"
			FileUtils.save(contents: content, inPath: "\(outputPath)/\(fileName)")
		}

		let content = swiftCode
		let fileName = FileUtils.swiftFileName(from: name)
		FileUtils.save(contents: content, inPath: "\(outputPath)/\(fileName)")
	}
}
