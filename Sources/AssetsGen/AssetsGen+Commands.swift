import ArgumentParser
import DeepDiff
import Foundation

struct Configs {
	fileprivate(set) static var outputPath: String!
	fileprivate(set) static var baseLang: LanguageKey!
	fileprivate(set) static var os: OS!
}

extension AssetsGen {
	struct Options: ParsableArguments {
		@Flag(
			name: .customLong("code-gen"),
			help: "Generate corresponding code"
		)
		var codeGeneration = false
		
		@Flag(
			help: "Prevent cleanup files before operation"
		)
		var noCleanup = false
		
		@Flag(help: "Filter only new keys")
		var filterKeys = false
		
		@Option(help: "Path to resources")
		var resourcesPath: String = ""
		
		@Option(help: "Path to xliff translations")
		var sourcesPath: String = ""
		
		@Option(help: "Path to input json index")
		var inputPath: String = ""
		
		@Option(help: "Path to save the output")
		var outputPath: String = ""

		@Option(help: "Path to generate code")
		var codeOutputPath: String = ""
		
		@Option(
			name: .customLong("proj"),
			help: "Name of the project"
		)
		var projectName: String = ""
		
		@Option(help: "List of the json source files")
		var files: String = ""
		
		@Option(help: "List of the xliff translated files")
		var sources: String = ""
		
		@Option(help: "List of the target languages")
		var langs: String = ""
		
		@Option(help: "Base language key")
		var baseLang: String = "en"
		
		@Option(help: "Target platform os: ios|android")
		var os: String = ""
		
		var filesValue: [String] {
			_array(from: files)
		}
		
		var sourcesValue: [String] {
			_array(from: sources)
		}
		
		var langsValue: [LanguageKey] {
			_array(from: langs)
				.map(LanguageKey.init)
		}
		
		var baseLangValue: LanguageKey {
			LanguageKey(stringLiteral: baseLang)
		}
		
		var osValue: OS {
			OS(stringLiteral: os)
		}
		
		private func _array(from string: String) -> [String] {
			string
				.split(separator: ",")
				.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
		}
	}
	
	class DefaultCommand: ParsableCommand {
		@OptionGroup()
		var options: Options
		
		required init() {}
		
		func run() throws {
			Configs.outputPath = options.outputPath
			Configs.baseLang = options.baseLangValue
			Configs.os = options.osValue
			
			if !options.noCleanup {
				print("Cleaning output...")
				FileUtils.remove(atPath: options.outputPath)
				print("Finished cleaning!")
			}
			
			runCommand()
		}
		
		func runCommand() {}
	}
	
	final class GenerateImages: DefaultCommand {
		override func runCommand() {
			print("Genrating images...")
			let generator = AssetsGenerator(
				inputPath: options.inputPath,
				resourcesPath: options.resourcesPath
			)
			generator.generate(
				outputPath: options.outputPath,
				resourcesPath: options.resourcesPath,
				codeGen: options.codeGeneration,
				codePath: options.codeOutputPath
			)
			print("Images generated successfully!")
		}
	}
	
	final class GenerateStrings: DefaultCommand {
		override func runCommand() {
			print("Genrating strings...")
			let generator = StringsGenerator(
				projectName: options.projectName,
				sources: .init(
					inputPath: options.inputPath,
					files: options.filesValue
				)
			)
			generator.generate(
				baseLang: options.baseLangValue,
				os: options.osValue,
				path: options.outputPath,
				codeGen: options.codeGeneration,
				codePath: options.codeOutputPath
			)
			print("Strings generated successfully!")
		}
	}
	
	final class GenerateTranslations: DefaultCommand {
		override func runCommand() {
			print("Genrating translations...")
			let generator = XLIFFGenerator(
				projectName: options.projectName,
				sources: .init(
					inputPath: options.inputPath,
					files: options.filesValue
				)
			)
			generator.generate(
				baseLang: options.baseLangValue,
				targetLangs: options.langsValue,
				filterExisting: options.filterKeys,
				outputPath: options.outputPath
			)
			print("Translations generated successfully!")
		}
	}
	
	final class ParseTranslations: DefaultCommand {
		override func runCommand() {
			print("Parsing translations...")
			let sources: [StringsSource] = .init(
				inputPath: options.sourcesPath,
				files: options.sourcesValue
			)
			let parser = XLIFFParser(sources: sources)
			parser.parse(
				inputPath: options.inputPath,
				files: options.filesValue,
				outputPath: options.outputPath
			)
			print("Translations parsed successfully!")
		}
	}
	
	final class GenerateSeedStrings: DefaultCommand {
		override func runCommand() {
			print("Generating seed strings...")
			let projectName = options.projectName.llamaCased
			let generator = XMLStringParser(
				inputPath: options.inputPath,
				expectedPostfix: "\(.*projectName).seed.xml",
				langs: options.langsValue
			)
			generator.generateSeed(
				path: options.outputPath,
				projectName: projectName
			)
			print("Seed strings generated successfully!")
		}
	}
	
	final class ParseXMLStrings: DefaultCommand {
		override func runCommand() {
			print("Parsing xml strings...")
			let projectName = options.projectName.llamaCased
			let generator = XMLStringParser(
				inputPath: options.inputPath,
				expectedPostfix: "\(.*projectName).xml",
				langs: options.langsValue
			)
			let sourceFile = options.sourcesValue.first ?? ""
			let sources: [StringsSource] = .init(
				inputPath: options.sourcesPath,
				files: [sourceFile]
			)
			guard let source = sources.first else {
				print("Source not found.")
				return
			}
			let changes = diff(old: source.strings, new: generator.strings)
			let replaces = changes.compactMap { $0.replace }
			let inserts = changes.compactMap { $0.insert }
			let deletes = changes.compactMap { $0.delete }
			let moves = changes.compactMap { $0.move }
			ParseReplacesFile.shared.write(replaces)
			ParseInsertsFile.shared.write(inserts)
			ParseDeletesFile.shared.write(deletes)
			ParseMovesFile.shared.write(moves)
			var newStrings = source.strings
			replaces.forEach { replace in
				if let index = newStrings.firstIndex(where: { $0.key == replace.newItem.key }),
					let value = replace.newItem.value(for: Configs.baseLang, with: Configs.os) {
					let newString = newStrings[index]
					newString.resetValues(to: value, for: Configs.baseLang)
					newStrings[index] = newString
				}
			}
			deletes.forEach { delete in
				if let index = newStrings.firstIndex(where: { $0.key == delete.item.key }) {
					newStrings.remove(at: index)
				}
			}
			inserts.forEach { insert in
				newStrings.insert(insert.item, at: insert.index)
			}
			moves.forEach({ move in
				newStrings[move.toIndex] = move.item
			})
			let fileName = "\(projectName).strings.json".replacingOccurrences(of: "..", with: ".")
			FileUtils.saveJSON(newStrings, inPath: options.outputPath / fileName)
			print("Parsed xml strings successfully!")
		}
	}
}
