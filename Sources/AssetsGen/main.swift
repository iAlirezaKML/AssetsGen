import Foundation
import SPMUtility

// let arguments = ProcessInfo.processInfo.arguments.dropFirst()
//
// let parser = ArgumentParser(
//	usage: "<options>",
//	overview: """
//	A Swift command-line tool to generate localized strings and xcassets with corresponding swift code based on json input
//	"""
// )
//
// let lookupArgument = parser.add(
//	option: "--lookup",
//	shortName: "-l",
//	kind: String.self,
//	usage: "The parent folder of input/output folders - default: ."
// )
//
// let inputArgument = parser.add(
//	option: "--input",
//	shortName: "-i",
//	kind: String.self,
//	usage: "The folder contains input files and resources - default: ${lookup}/input"
// )
//
// let stringSourceArgument = parser.add(
//	option: "--string-source",
//	shortName: "-s",
//	kind: String.self,
//	usage: "The name of the json file source for strings - default: \"stringSource.json\""
// )
//
// let assetSourceArgument = parser.add(
//	option: "--asset-source",
//	shortName: "-a",
//	kind: String.self,
//	usage: "The name of the json file source for assets - default: \"assetSource.json\""
// )
//
// let reourcesArgument = parser.add(
//	option: "--resources-path",
//	shortName: "-r",
//	kind: String.self,
//	usage: "The folder containing all resources to generate assets - default: ${input}/resources"
// )
//
// let outputArgument = parser.add(
//	option: "--output",
//	shortName: "-o",
//	kind: String.self,
//	usage: "The folder all generated files will be stored in - default: ${lookup}/output"
// )

// do {
//	let parsedArgs = try parser.parse(Array(arguments))
//	let lookupPath = parsedArgs.get(lookupArgument) ?? "."
//	let inputPath = parsedArgs.get(inputArgument) ?? "\(lookupPath)/input"
//	let stringSourceName = parsedArgs.get(stringSourceArgument) ?? "stringSource.json"
//	let assetSourceName = parsedArgs.get(assetSourceArgument) ?? "assetSource.json"
//	let resourcesPath = parsedArgs.get(reourcesArgument) ?? "\(inputPath)/resources"
//	let outputPath = parsedArgs.get(outputArgument) ?? "\(lookupPath)/output"
//
//	SwiftFormatter.setup()
//	FileUtils.remove(atPath: outputPath)
//
//	print("Genrating seed json...")
//	let parser = AndroidXMLParser(langs: ["en", "ar"], inputPath: inputPath)
//	parser.parse(outputPath: outputPath)
//	print("Seed json generated successfully!")
//
//	print("Genrating strings...")
//	let stringGen = StringGenerator(inputPath: "\(inputPath)/\(stringSourceName)")
//	stringGen?.generate(at: outputPath)
//	stringGen?.xmlDocument(at: outputPath)
//	print("Strings generated successfully!")
//
//	if let stringGen = stringGen {
//		print("Genrating translation...")
//		let convertor = XLIFFConverter(generator: stringGen)
//		convertor.parse(inputPath: "\(inputPath)/ar.xliff", outputPath: outputPath)
//		convertor.generate(basedOn: "en", filterExisting: true, outputPath: outputPath)
//		print("Translation generated successfully!")
//	}
//
//	print("Genrating assets...")
//	let assetGen = AssetsGenerator(inputPath: "\(inputPath)/\(assetSourceName)")
//	assetGen?.generate(at: outputPath, lookupAt: resourcesPath)
//	print("Assets generated successfully!")
//
//	print("Start formatting...")
//	SwiftFormatter.format(outputPath)
//	print("Finished formatting!")
// } catch {
//	print("Failed with \(error)")
// }

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

// enum Command {
//	case generateStrings(
//		inputPath: String,
//		outputPath: String,
//		projectName: String,
//		files: [String],
//		translationBaseLang: LanguageKey?,
//		translationFiltered: Bool?,
//		os: OS,
//		codeGeneration: Bool,
//		codeFormat: Bool
//	)
//	case parseTranslations(
//		inputPath: String,
//		outputPath: String,
//		files: [String],
//		sourcesPath: String,
//		sources: [String],
//		translationBaseLang: LanguageKey
//	)
//	case seedStrings(
//		inputPath: String,
//		outputPath: String,
//		langs: [LanguageKey]
//	)
//	case generateImages(
//		inputPath: String,
//		outputPath: String,
//		codeGeneration: Bool,
//		codeFormat: Bool
//	)
// }

do {
	let command = try Command()
	try command.run()
} catch {
	print(error)
}
