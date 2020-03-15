// import Foundation
//
// struct StringGenerator {
//	let name: String
//	let langs: Set<LanguageKey>
//	let strings: [StringsSource.StringItem]
//
//	init?(name: String = "LocalizedStrings", inputPath: String) {
//		guard
//			let strings: [StringsSource.StringItem] = FileUtils.value(atPath: inputPath)
//		else { return nil }
//		let langs = strings
//			.flatMap { $0.values.keys }
//			.reduce(into: Set<LanguageKey>()) { $0.insert($1) }
//			.filter { !$0.isSpecific }
//
//		self.name = name
//		self.langs = langs
//		self.strings = strings
//	}
//
//	func localized(for lang: LanguageKey) -> [StringsSource.StringItem.Content] {
//		strings
//			.compactMap { $0.localizable(lang: lang) }
//	}
//
//	func localizedContent(for lang: LanguageKey) -> String {
//		localized(for: lang)
//			.map { $0.localizedContent }
//			.joined(separator: "\n\n")
//	}
//
//	var swiftCode: SwiftCode {
//		let swiftCodes = strings
//			.flatMap { $0.swiftCode + [.newline] }
//		return [
//			.import("Foundation"),
//			.import("ZSWTaggedStringSwift"),
//			.newline,
//			.enum(
//				name: name,
//				content: swiftCodes
//			),
//		]
//	}
//
//	func xml(for lang: LanguageKey) -> XMLDocument {
//		let root = XMLElement(name: "resources")
//		let xml = XMLDocument(rootElement: root)
//		strings.compactMap { $0.xml(lang: lang) }.forEach(root.addChild)
//		return xml
//	}
// }
