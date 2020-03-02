import Foundation

public struct ContentsJSON: Codable {
	public struct Image: Codable {
		public enum Idiom: String, Codable {
			case universal
		}

		public enum Scale: String, Codable {
			case x1 = "1x"
			case x2 = "2x"
			case x3 = "3x"
		}

		public enum LanguageDirection: String, Codable {
			case leftToRight = "left-to-right"
		}

		public let idiom: Idiom
		public let filename: String
		public let scale: Scale?
		public let languageDirection: LanguageDirection?

		public init(
			idiom: Idiom = .universal,
			filename: String,
			scale: Scale?,
			languageDirection: LanguageDirection?
		) {
			self.idiom = idiom
			self.filename = filename
			self.scale = scale
			self.languageDirection = languageDirection
		}

		enum CodingKeys: String, CodingKey {
			case idiom
			case filename
			case scale
			case languageDirection = "language-direction"
		}
	}

	public struct Info: Codable {
		public let version: Int
		public let author: String

		public static let `default` = Info(
			version: 1,
			author: "xcode"
		)

		public init(
			version: Int,
			author: String
		) {
			self.version = version
			self.author = author
		}
	}

	public struct Properties: Codable {
		public let _providesNamespace: Bool?
		public let _preservesVectorRepresentation: Bool?

		public init(
			providesNamespace: Bool? = nil,
			preservesVectorRepresentation: Bool? = nil
		) {
			_providesNamespace = providesNamespace
			_preservesVectorRepresentation = preservesVectorRepresentation
		}

		public var providesNamespace: Bool {
			_providesNamespace ?? true
		}

		public var preservesVectorRepresentation: Bool {
			_preservesVectorRepresentation ?? true
		}

		enum CodingKeys: String, CodingKey {
			case _providesNamespace = "provides-namespace"
			case _preservesVectorRepresentation = "preserves-vector-representation"
		}
	}

	public let images: [Image]?
	public let info: Info
	public let properties: Properties?

	public init(
		images: [Image]? = nil,
		info: Info = .default,
		properties: Properties? = nil
	) {
		self.images = images
		self.info = info
		self.properties = properties
	}
}
