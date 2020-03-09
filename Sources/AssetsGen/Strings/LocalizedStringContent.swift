import Foundation

public struct LocalizedStringContent {
	public let lang: LocalizedLanguageKey
	public let comment: String
	public let key: String
	public let value: String

	public var localizedContent: String {
		String(
			format: "/* %@ */\n\"%@\" = \"%@\"",
			comment, key, value
		)
	}

	public var translationContent: String {
		String(
			format: "<p class=\"key\">%@</p>\n<p class=\"value\">%@</p>",
			key, value.escapedQuotes
		)
	}
}
