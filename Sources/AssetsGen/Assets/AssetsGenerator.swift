import Foundation

struct AssetsGenerator {
	let containers: [AssetsContainer]

	init(inputPath: String) {
		containers = FileUtils.value(atPath: inputPath) ?? []
	}

	func saveContentsJSON(_ json: ContentsJSON, path: String) {
		FileUtils.saveJSON(json, inPath: path / "Contents.json")
	}

	func copyResources(_ asset: ImageAsset, to path: String, from resourcesPath: String) {
		asset.resourcePaths.forEach {
			let from = resourcesPath / $0
			let to = path / $0
			FileUtils.copy(from: from, to: to)
		}
	}

	func generateAsset(_ asset: ImageAsset, at path: String, _ resourcesPath: String) {
		let assetPath = path / "\(asset.name).imageset"
		saveContentsJSON(asset.contentsJSON, path: assetPath)
		copyResources(asset, to: assetPath, from: resourcesPath)
	}

	func generate(outputPath: String, resourcesPath: String, codeGen: Bool) {
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

			if codeGen {
				// generate swift code
				let fileName = FileUtils.swiftFileName(from: container.name)
				FileUtils.save(contents: container.swiftCode.raw, inPath: outputPath / fileName)
			}
		}
	}
}
