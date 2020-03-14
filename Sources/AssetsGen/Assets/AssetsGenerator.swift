import Foundation

struct AssetsGenerator {
	let containers: [AssetsContainer]

	init?(inputPath: String) {
		guard
			let containers: [AssetsContainer] = FileUtils.value(atPath: inputPath)
		else { return nil }
		self.containers = containers
	}

	func saveContentsJSON(_ json: ContentsJSON, path: String) {
		FileUtils.save(json, inPath: path / "Contents.json")
	}

	func copyResources(for asset: ImageAsset, in path: String, at resourcesPath: String) {
		asset.resourcePaths.forEach {
			let from = resourcesPath / $0
			let to = path / $0
			FileUtils.copy(from: from, to: to)
		}
	}

	func generateAsset(_ asset: ImageAsset, at path: String, _ resourcesPath: String) {
		let assetPath = "\(path / asset.name).imageset"
		saveContentsJSON(asset.contentsJSON, path: assetPath)
		copyResources(for: asset, in: assetPath, at: resourcesPath)
	}

	func generate(at outputPath: String, lookupAt resourcesPath: String) {
		containers.forEach { container in
			let containerName = FileUtils.xcassetsFileName(from: container.name)
			let containerPath = outputPath / containerName
			saveContentsJSON(container.contentsJSON, path: containerPath)

			container.groups.forEach { group in
				let groupPath = containerPath / group.name
				saveContentsJSON(group.contentsJSON, path: groupPath)
				group.assets.forEach { generateAsset($0, at: groupPath, resourcesPath) }
			}
			container.assets.forEach { generateAsset($0, at: containerPath, resourcesPath) }

			// generate swift code
			let fileName = FileUtils.swiftFileName(from: container.name)
			FileUtils.save(contents: container.swiftCode.raw, inPath: outputPath / fileName)
		}
	}
}
