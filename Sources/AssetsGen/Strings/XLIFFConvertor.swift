import Foundation
import XMLCoder

struct XLIFFConverter {
	let generator: StringsGenerator

	init(generator: StringsGenerator) {
		self.generator = generator
	}

	func parse(inputPath: String, outputPath: String) {
		guard
			let source = FileUtils.data(atPath: inputPath)
		else { return }
		do {
			let xliff = try XMLDecoder().decode(XLIFF.self, from: source)
			let strings = parse(xliff: xliff)
			let data = try! JSONEncoder().encode(strings)
			let str = String(data: data, encoding: .utf8)
			let fileName = "strings.json"
			FileUtils.save(contents: str!, inPath: "\(outputPath)/\(fileName)")
		} catch {
			print(error)
		}
	}

	func parse(xliff: XLIFF) -> [LocalizedString] {
		let strings = generator.strings
		xliff.files.forEach { file in
			file.body.transUnits.forEach { unit in
				if let idx = strings.firstIndex(where: { $0.key == unit.id }),
					let value = unit.target {
					strings[idx].set(value, for: file.targetLanguage)
				}
			}
		}
		return strings
	}

	func generate(
		basedOn sourceLang: LanguageKey,
		targeting targetLang: LanguageKey,
		filterExisting: Bool,
		outputPath: String
	) {
		let sourceContents = generator.localized(for: sourceLang)
		let targetContents = generator.localized(for: targetLang)
		let sourceKeys = sourceContents.map { $0.key }
		let targetKeys = targetContents.map { $0.key }

		let keys = filterExisting ?
			sourceKeys.filter { !targetKeys.contains($0) } :
			sourceKeys

		guard !keys.isEmpty else {
			return
		}

		let xliff = XLIFF(
			files: [
				XLIFF.File(
					original: "StringsTest/\(sourceLang.langValue).lproj/Localizable.strings", // TODO: fix this
					sourceLanguage: sourceLang,
					targetLanguage: targetLang,
					body: XLIFF.File.Body(
						transUnits: keys.compactMap { key in
							guard
								let source = sourceContents.first(where: { $0.key == key })
							else { return nil }
							return XLIFF.File.Body.TransUnit(
								id: key,
								source: source.value,
								target: targetContents.first(where: { $0.key == key })?.value,
								note: source.comment
							)
						}
					)
				),
			]
		)
		let doc = XLIFFDocument(xliff: xliff)
		let content = doc.xml
			.xmlString(options: .nodePrettyPrint)
			.trimmingCharacters(in: .whitespacesAndNewlines)
		let contents = """
		<?xml version="1.0" encoding="UTF-8"?>
		\(content)
		"""
		let fileName = "\(targetLang.langValue).xliff"
		FileUtils.save(contents: contents, inPath: "\(outputPath)/\(fileName)")
	}

	func generate(
		basedOn sourceLang: LanguageKey,
		filterExisting: Bool,
		outputPath: String
	) {
		generate(
			basedOn: sourceLang,
			targeting: "any",
			filterExisting: filterExisting,
			outputPath: outputPath
		)
		generator.langs.filter { $0 != sourceLang }.forEach {
			generate(
				basedOn: sourceLang,
				targeting: $0,
				filterExisting: filterExisting,
				outputPath: outputPath
			)
		}
	}
}
