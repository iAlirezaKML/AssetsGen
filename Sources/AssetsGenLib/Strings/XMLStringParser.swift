import Foundation
import XMLCoder

class XMLStringParser {
	private(set) var strings: [StringsSource.StringItem] = []

	init(
		inputPath: String,
		expectedPostfix: String,
		langs: [LanguageKey]
	) {
		do {
			let decoder = XMLDecoder()
			let xmls = try langs.map { lang in
				inputPath / "\(lang.langValue)\(expectedPostfix)"
			}
			.map { path -> Data? in
				print(path)
				return FileUtils.data(atPath: path)
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

	func generateSeed(
		path outputPath: String,
		projectName: String
	) {
		let fileName = "seed.\(projectName).strings.json"
		FileUtils.saveJSON(strings, inPath: outputPath / fileName)
	}

	func parse(lang: LanguageKey, xml: AndroidXML) {
		let singles = xml.strings.map {
			StringsSource.StringItem(
				key: $0.name,
				comment: nil,
				type: $0.isAttributed ? .attributed : .single,
				variables: nil,
				values: [lang.langValue: .single($0.content ?? "")]
			)
		}
		let arrays = xml.stringArrays.map {
			StringsSource.StringItem(
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
