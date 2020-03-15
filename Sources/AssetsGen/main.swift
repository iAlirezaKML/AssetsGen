import Foundation
import SPMUtility

enum CommandError: Error {
	case noCommands
	case badCommand(String)
	case missingInputPath
	case missingOutputPath
	case missingProjectName
	case missingFiles
	case missingOS
}

class Command {
	let name: String
	let arguments: [String]

	let parser: ArgumentParser

	let inputPathArg: OptionArgument<String>
	let outputPathArg: OptionArgument<String>
	let sourcesPathArg: OptionArgument<String>
	let projectNameArg: OptionArgument<String>
	let filesArg: OptionArgument<String>
	let sourcesArg: OptionArgument<String>
	let langsArg: OptionArgument<String>
	let baseLangArg: OptionArgument<String>
	let filterKeysArg: OptionArgument<Bool>
	let osArg: OptionArgument<String>
	let codeGenerationArg: OptionArgument<Bool>
	let codeFormatArg: OptionArgument<Bool>
	let cleanupArg: OptionArgument<Bool>

	init() throws {
		var arguments = ProcessInfo.processInfo.arguments.dropFirst()
		guard let name = arguments.popFirst() else {
			throw CommandError.noCommands
		}
		self.name = String(name)
		self.arguments = Array(arguments)

		parser = ArgumentParser(
			usage: "<options>",
			overview: """
			AssetsGen generates localized strings and xcassets with corresponding swift code based on json input, or android's strings.xml.
			Also it can be used to generate and parse xliff translation sources to update json sources.
			"""
		)

		inputPathArg = parser.add(
			option: "--input-path",
			kind: String.self,
			usage: "eg. --input-path ./input/strings"
		)

		outputPathArg = parser.add(
			option: "--output-path",
			kind: String.self,
			usage: "eg. --output-path ./output"
		)

		sourcesPathArg = parser.add(
			option: "--sources-path",
			kind: String.self,
			usage: "eg. --sources-path ./input/strings"
		)

		projectNameArg = parser.add(
			option: "--proj",
			kind: String.self,
			usage: "eg. --proj MyApp"
		)

		filesArg = parser.add(
			option: "--files",
			kind: String.self,
			usage: "eg. --files InfoPlist.strings.json,Common.strings.json"
		)

		sourcesArg = parser.add(
			option: "--sources",
			kind: String.self,
			usage: "eg. --sources ar.xliff"
		)

		langsArg = parser.add(
			option: "--langs",
			kind: String.self,
			usage: "eg. --sources en,ar"
		)

		baseLangArg = parser.add(
			option: "--base-lang",
			kind: String.self,
			usage: "eg. --base-lang en"
		)

		filterKeysArg = parser.add(
			option: "--filter-keys",
			kind: Bool.self,
			usage: "eg. --filter-keys"
		)

		osArg = parser.add(
			option: "--os",
			kind: String.self,
			usage: "eg. --os ios"
		)

		codeGenerationArg = parser.add(
			option: "--code-gen",
			kind: Bool.self,
			usage: "eg. --code-gen"
		)

		codeFormatArg = parser.add(
			option: "--format-code",
			kind: Bool.self,
			usage: "eg. --format-code"
		)

		cleanupArg = parser.add(
			option: "--cleanup",
			kind: Bool.self,
			usage: "eg. --cleanup [defaults to true]"
		)
	}

	func run() throws {
		let args = try parser.parse(arguments)

		let inputPath = args.get(inputPathArg)
		let outputPath = args.get(outputPathArg)
		let sourcesPath = args.get(sourcesPathArg)
		let projectName = args.get(projectNameArg)
		let files = args.get(filesArg)?
			.split(separator: ",")
			.map(String.init)
		let sources = args.get(sourcesArg)?
			.split(separator: ",")
			.map(String.init)
		let filterKeys = args.get(filterKeysArg) ?? false
		let os = args.get(osArg)
		let langs = args.get(langsArg)?
			.split(separator: ",")
			.map(String.init)
			.map(LanguageKey.init)
			?? []
		let baseLang = LanguageKey(stringLiteral: args.get(baseLangArg) ?? "en")
		let codeGeneration = args.get(codeGenerationArg) ?? false
		let codeFormat = args.get(codeFormatArg) ?? false
		let cleanup = args.get(cleanupArg) ?? true

		if cleanup, let path = outputPath {
			self.cleanup(path: path)
		}

		switch name.lowercased() {
		case "gen-str":
			guard let inputPath = inputPath else {
				throw CommandError.missingInputPath
			}
			guard let outputPath = outputPath else {
				throw CommandError.missingOutputPath
			}
			guard let projectName = projectName else {
				throw CommandError.missingProjectName
			}
			guard let files = files else {
				throw CommandError.missingFiles
			}
			guard let os = os else {
				throw CommandError.missingOS
			}
			generateStrings(
				inputPath: inputPath,
				outputPath: outputPath,
				projectName: projectName,
				files: files,
				baseLang: baseLang,
				os: OS(stringLiteral: os),
				codeGeneration: codeGeneration
			)

		case "gen-trans":
			guard let inputPath = inputPath else {
				throw CommandError.missingInputPath
			}
			guard let outputPath = outputPath else {
				throw CommandError.missingOutputPath
			}
			guard let projectName = projectName else {
				throw CommandError.missingProjectName
			}
			guard let files = files else {
				throw CommandError.missingFiles
			}
			generateTranslations(
				inputPath: inputPath,
				outputPath: outputPath,
				projectName: projectName,
				files: files,
				baseLang: baseLang,
				langs: langs,
				filterKeys: filterKeys
			)

		case "parse-trans":
			guard let inputPath = inputPath else {
				throw CommandError.missingInputPath
			}
			guard let outputPath = outputPath else {
				throw CommandError.missingOutputPath
			}
			guard let files = files else {
				throw CommandError.missingFiles
			}
			parseTranslations(
				inputPath: inputPath,
				outputPath: outputPath,
				files: files,
				sourcesPath: sourcesPath,
				sources: sources
			)

		case "seed-str":
			guard let inputPath = inputPath else {
				throw CommandError.missingInputPath
			}
			guard let outputPath = outputPath else {
				throw CommandError.missingOutputPath
			}
			generateSeedStrings(
				inputPath: inputPath,
				outputPath: outputPath,
				langs: langs
			)

		default:
			throw CommandError.badCommand(name)
		}

		if codeGeneration, codeFormat, let path = outputPath {
			self.codeFormat(path: path)
		}
	}

	func generateStrings(
		inputPath: String,
		outputPath: String,
		projectName: String,
		files: [String],
		baseLang: LanguageKey,
		os: OS,
		codeGeneration: Bool
	) {
		print("Genrating strings...")
		let generator = StringsGenerator(
			projectName: projectName,
			sources: .init(inputPath: inputPath, files: files)
		)
		generator.generate(
			baseLang: baseLang,
			os: os,
			codeGen: codeGeneration,
			path: outputPath
		)
		print("Strings generated successfully!")
	}

	func generateTranslations(
		inputPath: String,
		outputPath: String,
		projectName: String,
		files: [String],
		baseLang: LanguageKey,
		langs: [LanguageKey],
		filterKeys: Bool
	) {
		print("Genrating translations...")
		let generator = XLIFFGenerator(
			projectName: projectName,
			sources: .init(inputPath: inputPath, files: files)
		)
		generator.generate(
			baseLang: baseLang,
			targetLangs: langs,
			filterExisting: filterKeys,
			outputPath: outputPath
		)
		print("Translations generated successfully!")
	}

	func parseTranslations(
		inputPath: String,
		outputPath: String,
		files: [String],
		sourcesPath: String?,
		sources: [String]?
	) {
		print("Parsing translations...")
		let sources: [StringsSource] = .init(
			inputPath: sourcesPath ?? "",
			files: sources ?? []
		)
		let parser = XLIFFParser(sources: sources)
		parser.parse(
			inputPath: inputPath,
			files: files,
			outputPath: outputPath
		)
		print("Translations parsed successfully!")
	}

	func generateSeedStrings(
		inputPath: String,
		outputPath: String,
		langs: [LanguageKey]
	) {
		print("Generating seed strings...")
		let generator = SeedGenerator(inputPath: inputPath, langs: langs)
		generator.generateSeed(path: outputPath)
		print("Seed strings generated successfully!")
	}

	func cleanup(path: String) {
		print("Cleaning output...")
		FileUtils.remove(atPath: path)
		print("Finished cleaning!")
	}

	func codeFormat(path: String) {
		print("Start formatting...")
		SwiftFormatter.setup()
		SwiftFormatter.format(path)
		print("Finished formatting!")
	}
}

do {
	let command = try Command()
	try command.run()
} catch {
	print(error)
}
