import Foundation

class AssetGroup: Codable {
	private let _hasNamespace: Bool?
	let name: String
	let assets: [ImageAsset]

	var hasNamespace: Bool {
		_hasNamespace ?? true
	}

	enum CodingKeys: String, CodingKey {
		case _hasNamespace = "namespace"
		case name
		case assets
	}

	lazy var contentsJSON: ContentsJSON = ContentsJSON(
		properties: ContentsJSON.Properties(providesNamespace: hasNamespace)
	)

	var swiftCode: SwiftCode {
		let name = self.name.capitalized
		let codes = assets
			.flatMap { $0.swiftCode(namespace: name) }
//			.joined(separator: "\n")
		return [
			.enum(
				name: name,
				content: codes
			),
		]

//		return """
//		public enum \(name) {
//		\(codes)
//		}
//		"""
	}
}
