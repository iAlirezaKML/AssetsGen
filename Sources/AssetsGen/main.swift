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
	let translationBaseLangArg: OptionArgument<String>
	let translationFilteredArg: OptionArgument<Bool>
	let osArg: OptionArgument<String>
	let codeGenerationArg: OptionArgument<Bool>
	let codeFormatArg: OptionArgument<Bool>

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

		translationBaseLangArg = parser.add(
			option: "--trans-base-lang",
			kind: String.self,
			usage: "eg. --trans-base-lang en"
		)

		translationFilteredArg = parser.add(
			option: "--trans-filtered",
			kind: Bool.self,
			usage: "eg. --trans-filtered"
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
	}

	func run() throws {
		let args = try parser.parse(arguments)
		switch name.lowercased() {
		case "gen-str":
			guard let inputPath = args.get(inputPathArg) else {
				throw CommandError.missingInputPath
			}
			guard let outputPath = args.get(outputPathArg) else {
				throw CommandError.missingOutputPath
			}
			guard let projectName = args.get(projectNameArg) else {
				throw CommandError.missingProjectName
			}
			guard let files = args.get(filesArg)?
				.split(separator: ",")
				.map(String.init)
			else {
				throw CommandError.missingFiles
			}
			guard let os = args.get(osArg) else {
				throw CommandError.missingOS
			}
			let translationBaseLang = args.get(translationBaseLangArg) ?? "en"
			let translationFiltered = args.get(translationFilteredArg) ?? false
			let codeGeneration = args.get(codeGenerationArg) ?? false
			let codeFormat = args.get(codeFormatArg) ?? false

			generateStrings(
				inputPath: inputPath,
				outputPath: outputPath,
				projectName: projectName,
				files: files,
				translationBaseLang: LanguageKey(stringLiteral: translationBaseLang),
				translationFiltered: translationFiltered,
				os: OS(stringLiteral: os),
				codeGeneration: codeGeneration,
				codeFormat: codeFormat
			)

		default:
			throw CommandError.badCommand(name)
		}
	}

	func generateStrings(
		inputPath: String,
		outputPath: String,
		projectName: String,
		files: [String],
		translationBaseLang _: LanguageKey?,
		translationFiltered _: Bool?,
		os: OS,
		codeGeneration: Bool,
		codeFormat: Bool
	) {
//		let cleanup = false
//		if cleanup {
		cleanup(path: outputPath)
//		}
		print("Genrating strings...")
		let stringGen = StringsGenerator(
			projectName: projectName,
			inputPath: inputPath,
			files: files
		)
		stringGen.generate(
			os: os,
			codeGen: codeGeneration,
			path: outputPath
		)
		print("Strings generated successfully!")
		if codeGeneration, codeFormat {
			self.codeFormat(path: outputPath)
		}
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
