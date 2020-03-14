import Foundation

struct AndroidXML: Codable {
	struct AndroidString: Codable {
		let name: String
		let content: String

		enum CodingKeys: String, CodingKey {
			case name
			case content = ""
		}

		var isAttributed: Bool {
			content.contains("<") && content.contains(">")
		}
	}

	struct AndroidStringArray: Codable {
		let name: String
		let items: [String]

		enum CodingKeys: String, CodingKey {
			case name
			case items = "item"
		}
	}

	let strings: [AndroidString]
	let stringArrays: [AndroidStringArray]

	enum CodingKeys: String, CodingKey {
		case strings = "string"
		case stringArrays = "string-array"
	}
}
