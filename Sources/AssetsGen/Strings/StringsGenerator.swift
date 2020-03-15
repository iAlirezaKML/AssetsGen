import Foundation

struct StringsGenerator {
	let projectName: String
	let sources: [StringsSource]

	init(projectName: String, sources: [StringsSource]) {
		self.projectName = projectName
		self.sources = sources
	}

	func generate(baseLang: LanguageKey, os: OS, codeGen: Bool, path: String) {
		sources.forEach { source in
			switch os {
			case .android:
				source.generateXMLFile(at: path, baseLang: baseLang)
			case .iOS:
				source.generateStringsFile(at: path)
				if codeGen {
					source.generateSwiftCode(at: path)
				}
			}
		}
	}
}
