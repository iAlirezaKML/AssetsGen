import Foundation

struct AssetsContainer: Codable {
	let name: String
	let groups: [AssetGroup]
	let assets: [ImageAsset]

	let contentsJSON = ContentsJSON()

	var swiftCode: SwiftCode {
		let groupsSwiftCodes = groups
			.flatMap { $0.swiftCode(namespace: nil) }
		let assetsSwiftCodes = assets
			.flatMap { $0.swiftCode(namespace: nil) }
		return [
			.import("UIKit"),
			.newline,
			.enum(
				name: name,
				content: [
					groupsSwiftCodes,
					assetsSwiftCodes,
				].flatMap { $0 }
			),
		]
	}
}
