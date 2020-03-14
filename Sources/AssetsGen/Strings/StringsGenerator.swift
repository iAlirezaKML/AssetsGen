import Foundation

struct StringsGenerator {
	let projectName: String
	let sources: [StringsSource]

	init(projectName: String, inputPath: String, files: [String]) {
		self.projectName = projectName
		sources = files.compactMap { FileUtils.value(atPath: inputPath / $0) }
	}

	func generate(os: OS, codeGen: Bool, path: String) {
		sources.forEach { source in
			switch os {
			case .android:
				source.generateXMLFile(at: path)
			case .iOS:
				source.generateStringsFile(at: path)
				if codeGen {
					source.generateSwiftCode(for: source.fileName, at: path)
				}
			}
		}
	}
}
