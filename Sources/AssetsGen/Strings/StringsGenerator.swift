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
		sources.forEach { source in
			// Duplicated Values
			Dictionary(
				grouping: source.strings,
				by: { $0.value(for: baseLang, with: os)?.localizableValue ?? "" }
			)
			.filter { $1.count > 1 }
			.forEach { key, values in
				DuplicateValuesFile.shared.write(
					source: source.fileName,
					value: key,
					duplicatedKeys: values.map { $0.key }
				)
			}

			// Duplicated Keys
			Dictionary(
				grouping: source.strings,
				by: { $0.key }
			)
				.filter { $1.count > 1 }
				.forEach { key, _ in
					DuplicateKeysFile.shared.write(
						source: source.fileName,
						key: key
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
