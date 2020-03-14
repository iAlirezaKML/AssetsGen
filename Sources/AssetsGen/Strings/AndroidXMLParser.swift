import Foundation
import XMLCoder

class AndroidXMLParser {
	private(set) var strings: [LocalizedString]

	init(
		strings: [LocalizedString] = [],
		langs: [LanguageKey],
		inputPath: String
	) {
		self.strings = strings

		do {
			let decoder = XMLDecoder()
			let xmls = try langs.map { lang in
				"\(inputPath)/\(lang.langValue).seed.xml"
			}
			.map { path in
				FileUtils.data(atPath: path)
			}
			.map { data -> AndroidXML? in
				if let data = data {
					return try decoder.decode(AndroidXML.self, from: data)
				} else {
					return nil
				}
			}
			zip(langs, xmls).forEach { lang, xml in
				guard let xml = xml else { return }
				parse(lang: lang, xml: xml)
			}
		} catch {
			print(error)
		}
	}

	func parse(outputPath: String) {
		do {
			let data = try JSONEncoder().encode(strings)
			let str = String(data: data, encoding: .utf8)
			let fileName = "seed.json"
			FileUtils.save(contents: str!, inPath: "\(outputPath)/\(fileName)")
		} catch {
			print(error)
		}
	}

	func parse(lang: LanguageKey, xml: AndroidXML) {
		let singles = xml.strings.map {
			LocalizedString(
				key: $0.name,
				comment: nil,
				type: $0.isAttributed ? .attributed : .single,
				variables: nil,
				values: [lang.langValue: .single($0.content)]
			)
		}
		let arrays = xml.stringArrays.map {
			LocalizedString(
				key: $0.name,
				comment: nil,
				type: .array,
				variables: nil,
				values: [lang.langValue: .array($0.items)]
			)
		}
		let newStrings = singles + arrays
		newStrings.forEach { newString in
			if let string = strings.first(where: { $0.key == newString.key }) {
				newString.values.forEach { key, value in
					string.set(value, for: key)
				}
			} else {
				strings.append(newString)
			}
		}
	}
}
