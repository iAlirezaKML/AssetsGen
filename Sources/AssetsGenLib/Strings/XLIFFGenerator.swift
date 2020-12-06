import Foundation
import XMLCoder

struct XLIFFGenerator {
	let projectName: String
	let sources: [StringsSource]

	init(projectName: String, sources: [StringsSource]) {
		self.projectName = projectName
		self.sources = sources
	}

	func generate(
		sourceLang: LanguageKey,
		targetLang: LanguageKey,
		filterExisting: Bool,
		outputPath: String
	) {
		let files = sources.compactMap { source in
			source.xliffFile(
				sourceLang: sourceLang,
				targetLang: targetLang,
				projectName: projectName,
				filterExisting: filterExisting
			)
		}
		let xliff = XLIFF(files: files)

		let doc = XLIFFDocument(xliff: xliff)
		let content = doc.xml
			.xmlString(options: .nodePrettyPrint)
			.trimmingCharacters(in: .whitespacesAndNewlines)
		let contents = """
		<?xml version="1.0" encoding="UTF-8"?>
		\(content)
		"""
		let fileName = "\(targetLang.langValue).xliff"
		FileUtils.save(contents: contents, inPath: outputPath / fileName)
	}

	func generate(
		baseLang: LanguageKey,
		targetLangs: [LanguageKey],
		filterExisting: Bool,
		outputPath: String
	) {
		targetLangs.filter { $0 != baseLang }.forEach {
			generate(
				sourceLang: baseLang,
				targetLang: $0,
				filterExisting: filterExisting,
				outputPath: outputPath
			)
		}
	}
}
