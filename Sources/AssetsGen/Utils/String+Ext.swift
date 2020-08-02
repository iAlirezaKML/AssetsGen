import Foundation

private enum CharacterCasing {
	case lower
	case upper
}

extension Unicode.Scalar {
	fileprivate var `case`: CharacterCasing? {
		if CharacterSet.uppercaseLetters.contains(self) {
			return .upper
		} else if CharacterSet.lowercaseLetters.contains(self) {
			return .lower
		} else {
			return nil
		}
	}
}

private enum StringCasing {
	case camel
	case llama
	case snake
}

private let _underscoreChar = "_"
private let _underscoreScalar = _underscoreChar.unicodeScalars.first

extension String {
	private var casingComponents: [String] {
		var result: [String] = []
		var buffer = ""
		let sourceStr = self
		let lastIdx = sourceStr.unicodeScalars.count - 1
		sourceStr.unicodeScalars.enumerated().forEach { idx, char in
			let caseSwitched: Bool
			let isUnderscore = char == _underscoreScalar
			if isUnderscore {
				caseSwitched = true
			} else if let last = buffer.unicodeScalars.last {
				if buffer.unicodeScalars.count == 1, char.case != last.case {
					caseSwitched = char.case == .upper && last.case == .lower
				} else {
					caseSwitched = char.case == .lower && last.case == .upper
				}
			} else {
				caseSwitched = false
			}
			if caseSwitched {
				let nextStart: String
				if isUnderscore {
					nextStart = ""
				} else if buffer.count > 1, let last = buffer.popLast() {
					nextStart = String(last)
				} else {
					nextStart = ""
				}
				result.append(buffer)
				buffer = nextStart
			}
			if !isUnderscore {
				buffer += String(char)
			}
			if idx == lastIdx {
				result.append(buffer)
			}
		}
		return result
	}
	
	private func toCase(_ case: StringCasing) -> String {
		var comps = casingComponents
		switch `case` {
		case .camel:
			if comps.count > 0 {
				comps = comps.map({ $0.unicodeScalars.first?.case != .upper ? $0.capitalized : $0 })
			}
			return comps.joined()
		case .llama:
			if comps.count > 0 {
				comps = comps.map({ $0.unicodeScalars.first?.case != .upper ? $0.capitalized : $0 })
				let first = comps[0]
				comps[0] = first.lowercased()
			}
			return comps.joined()
		case .snake:
			return comps
				.map { $0.lowercased() }
				.joined(separator: _underscoreChar)
		}
	}

	var camelCased: String {
		toCase(.camel)
	}

	var llamaCased: String {
		toCase(.llama)
	}

	var snakeCased: String {
		toCase(.snake)
	}
}


private let badChars = CharacterSet.alphanumerics.inverted

extension String {
	private var uppercasingFirst: String {
		prefix(1).uppercased() + dropFirst()
	}
	
	private var lowercasingFirst: String {
		prefix(1).lowercased() + dropFirst()
	}
	
	var swiftCamelCased: String {
		guard !isEmpty else {
			return ""
		}
		
		let pre = starts(with: "_") ? "_" : ""
		let parts = components(separatedBy: badChars)
		
		let first = String(describing: parts.first ?? "").lowercasingFirst
		let rest = parts.dropFirst().map { String($0).uppercasingFirst }
		
		return ([pre, first] + rest).joined(separator: "")
	}
}


extension String {
	var escapedQuotes: Self {
		replacingOccurrences(of: "\\\"", with: "\"")
	}

	var unescapedQuotes: Self {
		replacingOccurrences(of: "\"", with: #"\""#)
	}

	var unescapedNewLine: Self {
		replacingOccurrences(of: "\n", with: #"\n"#)
	}
}

func / (lhs: String, rhs: String) -> String {
	let char = !lhs.isEmpty && !rhs.isEmpty ? "/" : ""
	return "\(lhs)\(char)\(rhs)"
}

func - (lhs: String, rhs: String) -> String {
	let char = !lhs.isEmpty && !rhs.isEmpty ? "-" : ""
	return "\(lhs)\(char)\(rhs)"
}

prefix operator .*

prefix func .* (lhs: String) -> String {
	let char = !lhs.isEmpty ? "." : ""
	return "\(char)\(lhs)"
}
