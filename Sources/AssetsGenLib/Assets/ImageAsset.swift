import Foundation

class ImageAsset: Codable {
	enum AssetType: String, Codable {
		case single
		case set
	}

	struct Attributes: Codable {
		let languageDirection: ContentsJSON.Image.LanguageDirection?

		init(
			languageDirection: ContentsJSON.Image.LanguageDirection?
		) {
			self.languageDirection = languageDirection
		}

		enum CodingKeys: String, CodingKey {
			case languageDirection = "language-direction"
		}
	}

	private let _type: AssetType?
	private let _isVector: Bool?
	private let _isTemplate: Bool?
	private let _codeOnly: Bool?
	let name: String
	let filename: String
	let attributes: Attributes?

	var type: AssetType {
		_type ?? .single
	}

	var isVector: Bool {
		_isVector ?? true
	}
	
	var isTemplate: Bool {
		_isTemplate ?? true
	}
	
	var codeOnly: Bool {
		_codeOnly ?? false
	}

	enum CodingKeys: String, CodingKey {
		case _type = "type"
		case _isVector = "vector"
		case _isTemplate = "template"
		case _codeOnly = "codeOnly"
		case name
		case filename
		case attributes
	}

	var resourcesPath: String?

	private var _imgs: [ContentsJSON.Image]?
	private var _res: [String]?
	private var _props: ContentsJSON.Properties?

	private func _calculate() {
		guard !codeOnly else { return } // skip if is codeOnly
		switch type {
		case .single:
			_imgs = [
				ContentsJSON.Image(
					idiom: .universal,
					filename: filename,
					scale: nil,
					languageDirection: attributes?.languageDirection
				),
			]
			_res = [filename]
			_props = ContentsJSON.Properties(
				preservesVectorRepresentation: isVector,
				templateRenderingIntent: isTemplate ? .template : .original
			)
		case .set:
			let fileParts = filename.split(separator: ".")
			let fileExt = fileParts.last ?? ""
			let baseName = fileParts.dropLast().joined(separator: ".")
			let postfixes = ["", "@2x", "@3x"]
			_imgs = []
			_res = []
			postfixes.enumerated().forEach {
				let fileName = "\(baseName)\($0.element).\(fileExt)"
				let scaleRaw = "\($0.offset + 1)x"
				let filePath = (resourcesPath ?? "") / fileName
				guard FileUtils.fileExists(at: filePath) else { return }
				_imgs?.append(
					ContentsJSON.Image(
						idiom: .universal,
						filename: fileName,
						scale: ContentsJSON.Image.Scale(rawValue: scaleRaw),
						languageDirection: attributes?.languageDirection
					)
				)
				_res?.append(fileName)
			}
			_props = nil
		}
	}

	private func _calculateIfNeeded() {
		if _res == nil || _res == nil {
			_calculate()
		}
	}

	lazy var contentsJSON: ContentsJSON = {
		_calculateIfNeeded()
		return ContentsJSON(
			images: _imgs,
			properties: _props
		)
	}()

	lazy var resourcePaths: [String] = {
		_calculateIfNeeded()
		return _res ?? []
	}()

	func swiftCode(namespace: String?) -> SwiftCode {
		let prefix: String
		if let namespace = namespace, !namespace.isEmpty {
			prefix = "\(namespace)/"
		} else {
			prefix = ""
		}
		let imageName = "\(prefix)\(name)"
		let funcName = name.swiftCamelCased
		return [
			.funcReturnUIImage(
				name: funcName,
				imageName: imageName
			),
		]
	}
}
