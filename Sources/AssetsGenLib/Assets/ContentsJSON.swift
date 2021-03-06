import Foundation

struct ContentsJSON: Codable {
	struct Image: Codable {
		enum Idiom: String, Codable {
			case universal
		}

		enum Scale: String, Codable {
			case x1 = "1x"
			case x2 = "2x"
			case x3 = "3x"
		}

		enum LanguageDirection: String, Codable {
			case leftToRight = "left-to-right"
		}

		let idiom: Idiom
		let filename: String
		let scale: Scale?
		let languageDirection: LanguageDirection?

		init(
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

	struct Info: Codable {
		let version: Int
		let author: String

		static let `default` = Info(
			version: 1,
			author: "xcode"
		)

		init(
			version: Int,
			author: String
		) {
			self.version = version
			self.author = author
		}
	}

	enum TemplateRenderingIntent: String, Codable {
		case template
		case original
	}

	struct Properties: Codable {
		let _providesNamespace: Bool?
		let _preservesVectorRepresentation: Bool?
		let _templateRenderingIntent: TemplateRenderingIntent?

		init(
			providesNamespace: Bool? = nil,
			preservesVectorRepresentation: Bool? = nil,
			templateRenderingIntent: TemplateRenderingIntent? = nil
		) {
			_providesNamespace = providesNamespace
			_preservesVectorRepresentation = preservesVectorRepresentation
			_templateRenderingIntent = templateRenderingIntent
		}

		var providesNamespace: Bool {
			_providesNamespace ?? true
		}

		var preservesVectorRepresentation: Bool {
			_preservesVectorRepresentation ?? true
		}

		var templateRenderingIntent: TemplateRenderingIntent {
			_templateRenderingIntent ?? .template
		}

		enum CodingKeys: String, CodingKey {
			case _providesNamespace = "provides-namespace"
			case _preservesVectorRepresentation = "preserves-vector-representation"
			case _templateRenderingIntent = "template-rendering-intent"
		}
	}

	let images: [Image]?
	let info: Info
	let properties: Properties?

	init(
		images: [Image]? = nil,
		info: Info = .default,
		properties: Properties? = nil
	) {
		self.images = images
		self.info = info
		self.properties = properties
	}
}
