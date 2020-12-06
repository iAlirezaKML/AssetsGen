import Foundation

struct XLIFF: Codable {
	struct File: Codable {
		struct Header: Codable {
			struct Tool: Codable {
				let id: String
				let name: String
				let version: String
				let buildNum: String

				public init(
					id: String = "com.apple.dt.xcode",
					name: String = "Xcode",
					version: String = "11.3.1",
					buildNum: String = "11C504"
				) {
					self.id = id
					self.name = name
					self.version = version
					self.buildNum = buildNum
				}

				enum CodingKeys: String, CodingKey {
					case id = "tool-id"
					case name = "tool-name"
					case version = "tool-version"
					case buildNum = "build-num"
				}

				var xml: XMLElement {
					let el = XMLElement(name: XLIFF.File.Header.CodingKeys.tool.rawValue)
					el.setAttributesWith([
						CodingKeys.id.rawValue: id,
						CodingKeys.name.rawValue: name,
						CodingKeys.version.rawValue: version,
						CodingKeys.buildNum.rawValue: buildNum,
					])
					return el
				}
			}

			let tool: Tool = Tool()

			enum CodingKeys: String, CodingKey {
				case tool
			}

			var xml: XMLElement {
				let el = XMLElement(name: XLIFF.File.CodingKeys.header.rawValue)
				el.addChild(tool.xml)
				return el
			}
		}

		struct Body: Codable {
			struct TransUnit: Codable {
				let id: String
				let xmlSpace: String
				let source: String
				let target: String?
				let note: String?

				public init(
					id: String,
					xmlSpace: String = "preserve",
					source: String,
					target: String?,
					note: String?
				) {
					self.id = id
					self.xmlSpace = xmlSpace
					self.source = source
					self.target = target
					self.note = note
				}

				enum CodingKeys: String, CodingKey {
					case id
					case xmlSpace = "xml:space"
					case source
					case target
					case note
				}

				var xml: XMLElement {
					let el = XMLElement(name: XLIFF.File.Body.CodingKeys.transUnits.rawValue)
					el.setAttributesWith([
						CodingKeys.id.rawValue: id,
						CodingKeys.xmlSpace.rawValue: xmlSpace,
					])
					el.addChild(XMLElement.make(name: CodingKeys.source.rawValue, value: source))
					if let target = target, !target.isEmpty {
						el.addChild(XMLElement.make(name: CodingKeys.target.rawValue, value: target))
					}
					el.addChild(XMLElement(name: CodingKeys.note.rawValue, stringValue: note))
					return el
				}
			}

			let transUnits: [TransUnit]

			enum CodingKeys: String, CodingKey {
				case transUnits = "trans-unit"
			}

			var xml: XMLElement {
				let el = XMLElement(name: XLIFF.File.CodingKeys.body.rawValue)
				transUnits.map { $0.xml }.forEach(el.addChild)
				return el
			}
		}

		let original: String
		let sourceLanguage: LanguageKey
		let targetLanguage: LanguageKey
		let dataType: String
		let header: Header
		let body: Body

		public init(
			original: String,
			sourceLanguage: LanguageKey,
			targetLanguage: LanguageKey,
			dataType: String = "plaintext",
			header: Header = Header(),
			body: Body
		) {
			self.original = original
			self.sourceLanguage = sourceLanguage
			self.targetLanguage = targetLanguage
			self.dataType = dataType
			self.header = header
			self.body = body
		}

		enum CodingKeys: String, CodingKey {
			case original
			case sourceLanguage = "source-language"
			case targetLanguage = "target-language"
			case dataType = "datatype"
			case header
			case body
		}

		var xml: XMLElement {
			let el = XMLElement(name: XLIFF.CodingKeys.files.rawValue)
			el.setAttributesWith([
				CodingKeys.original.rawValue: original,
				CodingKeys.sourceLanguage.rawValue: sourceLanguage.langValue,
				CodingKeys.targetLanguage.rawValue: targetLanguage.langValue,
				CodingKeys.dataType.rawValue: dataType,
			])
			el.addChild(header.xml)
			el.addChild(body.xml)
			return el
		}
	}

	let xmlns: String
	let xsi: String
	let version: String
	let schemaLocation: String
	let files: [File]

	public init(
		xmlns: String = "urn:oasis:names:tc:xliff:document:1.2",
		xsi: String = "http://www.w3.org/2001/XMLSchema-instance",
		version: String = "1.2",
		schemaLocation: String = "urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd",
		files: [File]
	) {
		self.xmlns = xmlns
		self.xsi = xsi
		self.version = version
		self.schemaLocation = schemaLocation
		self.files = files
	}

	enum CodingKeys: String, CodingKey {
		case xmlns
		case xsi = "xmlns:xsi"
		case version
		case schemaLocation = "xsi:schemaLocation"
		case files = "file"
	}

	var xml: XMLElement {
		let el = XMLElement(name: XLIFFDocument.CodingKeys.xliff.rawValue)
		el.setAttributesWith([
			CodingKeys.xmlns.rawValue: xmlns,
			CodingKeys.xsi.rawValue: xsi,
			CodingKeys.version.rawValue: version,
			CodingKeys.schemaLocation.rawValue: schemaLocation,
		])
		files.map { $0.xml }.forEach(el.addChild)
		return el
	}
}

struct XLIFFDocument: Codable {
	let xliff: XLIFF

	enum CodingKeys: String, CodingKey {
		case xliff
	}

	var xml: XMLDocument {
		let xml = XMLDocument(rootElement: xliff.xml)
		return xml
	}
}
