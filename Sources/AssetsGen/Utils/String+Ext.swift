import Foundation

private enum CharacterCasing {
	case lower
	case upper
}

extension Unicode.Scalar {
	fileprivate var `case`: CharacterCasing {
		if CharacterSet.uppercaseLetters.contains(self) {
			return .upper
		}
		return .lower
	}
}

private enum StringCasing {
	case camel
	case llama
	case snake
}

extension String {
	private var casingComponents: [String] {
		var result: [String] = []
		var buffer = ""
		let lastIdx = unicodeScalars.count - 1
		unicodeScalars.enumerated().forEach { idx, char in
			let caseSwitched: Bool

			if let last = buffer.unicodeScalars.last {
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
				if buffer.count > 1, let last = buffer.popLast() {
					nextStart = String(last)
				} else {
					nextStart = ""
				}
				result.append(buffer)
				buffer = nextStart
			}
			buffer += String(char)
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
				let first = comps[0]
				comps[0] = first.uppercased()
			}
			return comps.joined()
		case .llama:
			if comps.count > 0 {
				let first = comps[0]
				comps[0] = first.lowercased()
			}
			return comps.joined()
		case .snake:
			return comps
				.map { $0.lowercased() }
				.joined(separator: "_")
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

extension String {
	var escapedQuotes: Self {
		replacingOccurrences(of: "\\\"", with: "\"")
	}

	var unescapedQuotes: Self {
		replacingOccurrences(of: "\"", with: #"\""#)
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
