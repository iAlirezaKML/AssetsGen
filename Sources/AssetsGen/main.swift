import Foundation
import SPMUtility

let arguments = ProcessInfo.processInfo.arguments.dropFirst()

let parser = ArgumentParser(
	usage: "<options>",
	overview: """
	A Swift command-line tool to generate localized strings and xcassets with corresponding swift code based on json input
	"""
)

let lookupArgument = parser.add(
	option: "--lookup",
	shortName: "-l",
	kind: String.self,
	usage: "The parent folder of input/output folders - default: ."
)

let inputArgument = parser.add(
	option: "--input",
	shortName: "-i",
	kind: String.self,
	usage: "The folder contains input files and resources - default: ${lookup}/input"
)

let stringSourceArgument = parser.add(
	option: "--string-source",
	shortName: "-s",
	kind: String.self,
	usage: "The name of the json file source for strings - default: \"stringSource.json\""
)

let assetSourceArgument = parser.add(
	option: "--asset-source",
	shortName: "-a",
	kind: String.self,
	usage: "The name of the json file source for assets - default: \"assetSource.json\""
)

let reourcesArgument = parser.add(
	option: "--resources-path",
	shortName: "-r",
	kind: String.self,
	usage: "The folder containing all resources to generate assets - default: ${input}/resources"
)

let outputArgument = parser.add(
	option: "--output",
	shortName: "-o",
	kind: String.self,
	usage: "The folder all generated files will be stored in - default: ${lookup}/output"
)

do {
	let parsedArgs = try parser.parse(Array(arguments))
	let lookupPath = parsedArgs.get(lookupArgument) ?? "."
	let inputPath = parsedArgs.get(inputArgument) ?? "\(lookupPath)/input"
	let stringSourceName = parsedArgs.get(stringSourceArgument) ?? "stringSource.json"
	let assetSourceName = parsedArgs.get(assetSourceArgument) ?? "assetSource.json"
	let resourcesPath = parsedArgs.get(reourcesArgument) ?? "\(inputPath)/resources"
	let outputPath = parsedArgs.get(outputArgument) ?? "\(lookupPath)/output"

	SwiftFormatter.setup()
	FileUtils.remove(atPath: outputPath)

	print("Genrating strings...")
	let stringGen = LocalizedStringsGenerator(inputPath: "\(inputPath)/\(stringSourceName)")
	stringGen?.generate(at: outputPath)
	print("Strings generated successfully!")

	print("Genrating assets...")
	let assetGen = AssetsGenerator(inputPath: "\(inputPath)/\(assetSourceName)")
	assetGen?.generate(at: outputPath, lookupAt: resourcesPath)
	print("Assets generated successfully!")

	print("Start formatting...")
	SwiftFormatter.format(outputPath)
	print("Finished formatting!")
} catch {
	print("Failed with \(error)")
}
