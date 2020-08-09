import Foundation

struct StringsGenerator {
	let projectName: String
	let sources: [StringsSource]

	init(projectName: String, sources: [StringsSource]) {
		self.projectName = projectName
		self.sources = sources
	}

	func analyze(
		baseLang: LanguageKey,
		os: OS
	) {
		let file = AnalyzedDuplicatesFile.shared
		sources.forEach { source in
			let crossReference = Dictionary(
				grouping: source.strings,
				by: { $0.value(for: baseLang, with: os)?.localizableValue ?? "" }
			)
			let duplicates = crossReference.filter { $1.count > 1 }
			duplicates.forEach { key, values in
				file.write(
					source: source.fileName,
					value: key,
					duplicatedKeys: values.map { $0.key }
				)
			}
		}
	}

	func generate(
		baseLang: LanguageKey,
		os: OS,
		path: String,
		codeGen: Bool,
		codePath: String? = nil
	) {
		sources.forEach { source in
			switch os {
			case .android:
				source.generateXMLFile(at: path, baseLang: baseLang)
			case .iOS:
				source.generateStringsFile(at: path)
				if codeGen {
					source.generateSwiftCode(at: codePath || path)
				}
			}
		}
	}
}
