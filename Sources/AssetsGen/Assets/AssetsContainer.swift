import Foundation

public struct AssetsContainer: Codable {
	public let name: String
	public let groups: [AssetGroup]
	public let assets: [ImageAsset]

	public let contentsJSON = ContentsJSON()

	public var swiftCode: LocalizedStringSwiftCode {
		let groupsSwiftCodes = groups
			.map { $0.swiftCode }
			.joined(separator: "\n")
		let assetsSwiftCodes = assets
			.map { $0.swiftCode(namespace: nil) }
			.joined(separator: "\n")
		return """
		import UIKit
		
		public enum \(name) {
		\(groupsSwiftCodes)
		\(assetsSwiftCodes)
		}
		"""
	}
}
