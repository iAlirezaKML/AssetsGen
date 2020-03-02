import Foundation

private let badChars = CharacterSet.alphanumerics.inverted

extension String {
	public var unescapedQuotes: Self {
		replacingOccurrences(of: "\"", with: #"\""#)
	}

	public var uppercasingFirst: String {
		prefix(1).uppercased() + dropFirst()
	}

	public var lowercasingFirst: String {
		prefix(1).lowercased() + dropFirst()
	}

	public var camelCased: String {
		guard !isEmpty else {
			return ""
		}

		let parts = components(separatedBy: badChars)

		let first = String(describing: parts.first!).lowercasingFirst
		let rest = parts.dropFirst().map { String($0).uppercasingFirst }

		return ([first] + rest).joined(separator: "")
	}
}

public func / (lhs: String, rhs: String) -> String {
	let char = !lhs.isEmpty && !rhs.isEmpty ? "/" : ""
	return "\(lhs)\(char)\(rhs)"
}
