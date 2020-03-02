import Foundation

public class ImageAsset: Codable {
	public enum AssetType: String, Codable {
		case single
		case set
	}

	public struct Attributes: Codable {
		public let languageDirection: ContentsJSON.Image.LanguageDirection?

		public init(
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
	public let name: String
	public let filename: String
	public let attributes: Attributes?

	public var type: AssetType {
		_type ?? .single
	}

	public var isVector: Bool {
		_isVector ?? true
	}

	enum CodingKeys: String, CodingKey {
		case _type = "type"
		case _isVector = "vector"
		case name
		case filename
		case attributes
	}

	private var _imgs: [ContentsJSON.Image]?
	private var _res: [String]?
	private var _props: ContentsJSON.Properties?

	private func _calculate() {
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
			_props = ContentsJSON.Properties(preservesVectorRepresentation: isVector)
		case .set:
			let fileParts = filename.split(separator: ".")
			let (baseName, fileExt) = (fileParts[0], fileParts[1])
			let postfixes = ["", "@2x", "@3x"]
			_imgs = []
			_res = []
			postfixes.enumerated().forEach {
				let fileName = "\(baseName)\($0.element).\(fileExt)"
				let scaleRaw = "\($0.offset + 1)x"
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

	public lazy var contentsJSON: ContentsJSON = {
		_calculateIfNeeded()
		return ContentsJSON(
			images: _imgs,
			properties: _props
		)
	}()

	public lazy var resourcePaths: [String] = {
		_calculateIfNeeded()
		return _res ?? []
	}()

	public func swiftCode(namespace: String?) -> LocalizedStringSwiftCode {
		let prefix: String
		if let namespace = namespace, !namespace.isEmpty {
			prefix = "\(namespace)/"
		} else {
			prefix = ""
		}
		let imageName = "\(prefix)\(name)"
		let funcName = name.camelCased
		return """
		public static func \(funcName)() -> UIImage? {
		return UIImage(named: "\(imageName)")
		}
		"""
	}
}
