import Foundation

class AssetGroup: Codable {
	private let _hasNamespace: Bool?
	private let _skipCodeGen: Bool?
	private let _codeOnly: Bool?

	let name: String
	let groups: [AssetGroup]?
	let assets: [ImageAsset]?

	var hasNamespace: Bool {
		_hasNamespace ?? true
	}

	var skipCodeGen: Bool {
		_skipCodeGen ?? false
	}

	var codeOnly: Bool {
		_codeOnly ?? false
	}

	enum CodingKeys: String, CodingKey {
		case _hasNamespace = "namespace"
		case _skipCodeGen = "skipCodeGen"
		case _codeOnly = "codeOnly"
		case name
		case groups
		case assets
	}

	lazy var contentsJSON: ContentsJSON = ContentsJSON(
		properties: ContentsJSON.Properties(providesNamespace: hasNamespace)
	)

	func swiftCode(namespace: String?) -> SwiftCode {
		guard !skipCodeGen else { return [] }
		let prefix: String
		if let namespace = namespace, !namespace.isEmpty {
			prefix = "\(namespace)/"
		} else {
			prefix = ""
		}
		let name = self.name.camelCased
		var codes = groups?
			.flatMap { $0.swiftCode(namespace: prefix + name) } ?? []
		codes.append(
			contentsOf: assets?
				.flatMap { $0.swiftCode(namespace: prefix + name) } ?? []
		)
		return [
			.enum(
				name: name,
				content: codes
			),
		]
	}
}
