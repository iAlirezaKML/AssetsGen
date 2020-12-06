import Foundation
import XMLCoder

struct AndroidXML: Codable {
	struct AndroidString: Codable {
		let name: String
		let content: String?

		enum CodingKeys: String, CodingKey {
			case name
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			name = try container.decode(String.self, forKey: .name)
			let singleContainer = try decoder.singleValueContainer()
			content = try singleContainer.decode(String?.self)
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(name, forKey: .name)
			var singleContainer = encoder.singleValueContainer()
			try singleContainer.encode(content)
		}

		var isAttributed: Bool {
			if let content = content {
				return content.contains("<") && content.contains(">")
			} else {
				// original string had some tags,
				// and we couldn't parse raw string value,
				// so it should be attributed
				return true
			}
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
