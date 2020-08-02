import Foundation

// func SwiftCode(_ template: SwiftCodeTemplate) -> String {
//	return template.code
// }

typealias SwiftCode = [SwiftCodeTemplate]

enum SwiftCodeTemplate {
	case newline
	case `import`(_ name: String)
	case funcReturnString(
		name: String,
		key: String,
		tableName: String,
		comment: String,
		args: String,
		vars: String
	)
	case funcReturnAttributedString(
		name: String,
		key: String,
		tableName: String,
		comment: String,
		args: String,
		vars: String
	)
	case funcReturnStringArray(
		name: String,
		key: String,
		tableName: String,
		comment: String
	)
	case funcReturnUIImage(
		name: String,
		imageName: String
	)
	case `enum`(
		name: String,
		content: SwiftCode
	)

	var code: String {
		switch self {
		case .newline:
			return "\n"

		case let .import(name):
			return "import \(name)"

		case let .funcReturnString(name, key, tableName, comment, args, vars):
			return """
			public static func \(name)(\(args)) -> String {
			return String(
			format: NSLocalizedString(
			"\(key)",
			tableName: "\(tableName)",
			comment: "\(comment)"
			)\(vars)
			)
			}
			"""

		case let .funcReturnAttributedString(name, key, tableName, comment, args, vars):
			return """
			public static func \(name)(\(args)) -> NSAttributedString? {
			return try? ZSWTaggedString(
			format: NSLocalizedString(
			"\(key)",
			tableName: "\(tableName)",
			comment: "\(comment)"
			)\(vars)
			).attributedString()
			}
			"""

		case let .funcReturnStringArray(name, key, tableName, comment):
			return """
			public static func \(name)() -> [String] {
			return parseItems(
			NSLocalizedString(
			"\(key)",
			tableName: "\(tableName)",
			comment: "\(comment)"
			)
			)
			}
			"""

		case let .funcReturnUIImage(name, imageName):
			return """
			public static func \(name)() -> UIImage? {
			return UIImage(named: "\(imageName)")
			}
			"""

		case let .enum(name, content):
			return """
			public enum \(name) {
			\(content.raw)
			}
			"""
		}
	}
}

extension Array where Element == SwiftCodeTemplate {
	var raw: String {
		map { $0.code }
			.joined(separator: "\n")
	}
}
