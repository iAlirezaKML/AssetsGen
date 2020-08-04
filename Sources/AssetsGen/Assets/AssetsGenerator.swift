import Foundation

struct AssetsGenerator {
	let containers: [AssetsContainer]

	init(inputPath: String, resourcesPath: String) {
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
		asset.resourcesPath = resourcesPath
		let assetPath = path / "\(asset.name).imageset"
		saveContentsJSON(asset.contentsJSON, path: assetPath)
		copyResources(asset, to: assetPath, from: resourcesPath)
	}

	func generateGroup(_ group: AssetGroup, at path: String, _ resourcesPath: String) {
		let groupPath = path / group.name
		saveContentsJSON(group.contentsJSON, path: groupPath)
		group.groups?.forEach { generateGroup($0, at: groupPath, resourcesPath) }
		group.assets?.forEach { generateAsset($0, at: groupPath, resourcesPath) }
	}

	func generate(
		outputPath: String,
		resourcesPath: String,
		codeGen: Bool,
		codePath: String? = nil
	) {
		containers.forEach { container in
			let containerName = FileUtils.xcassetsFileName(from: container.name)
			let containerPath = outputPath / containerName
			saveContentsJSON(container.contentsJSON, path: containerPath)

			container.groups.forEach { group in
				generateGroup(group, at: containerPath, resourcesPath)
			}
			container.assets.forEach { generateAsset($0, at: containerPath, resourcesPath) }

			if codeGen {
				// generate swift code
				print(codePath)
				let fileName = FileUtils.swiftFileName(from: container.name .+ "images")
				FileUtils.save(contents: container.swiftCode.raw, inPath: (codePath || outputPath) / fileName)
			}
		}
	}
}
