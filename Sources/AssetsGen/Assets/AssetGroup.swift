import Foundation

public class AssetGroup: Codable {
	private let _hasNamespace: Bool?
	public let name: String
	public let assets: [ImageAsset]

	public var hasNamespace: Bool {
		_hasNamespace ?? true
	}

	enum CodingKeys: String, CodingKey {
		case _hasNamespace = "namespace"
		case name
		case assets
	}

	public lazy var contentsJSON: ContentsJSON = ContentsJSON(
		properties: ContentsJSON.Properties(providesNamespace: hasNamespace)
	)

	public var swiftCode: LocalizedStringSwiftCode {
		let name = self.name.capitalized
		let codes = assets
			.map { $0.swiftCode(namespace: name) }
			.joined(separator: "\n")
		return """
		public enum \(name) {
		\(codes)
		}
		"""
	}
}
