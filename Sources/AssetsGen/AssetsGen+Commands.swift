import ArgumentParser
import DeepDiff
import Foundation

extension AssetsGen {
	struct Options: ParsableArguments {
		@Flag(
			name: .customLong("code-gen"),
			help: "Generate corresponding code"
		)
		var codeGeneration = false
		
		@Flag(
			name: .customLong("format-code"),
			help: "Format generated code"
		)
		var codeFormat = false
		
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
			if !options.noCleanup {
				print("Cleaning output...")
				FileUtils.remove(atPath: options.outputPath)
				print("Finished cleaning!")
			}

			runCommand()
			
			if options.codeGeneration, options.codeFormat {
				print("Start formatting...")
				SwiftFormatter.setup()
				SwiftFormatter.format(options.outputPath)
				print("Finished formatting!")
			}
		}
		
		func runCommand() {}
	}
	
	final class GenerateImages: DefaultCommand {
		override func runCommand() {
			print("Genrating images...")
			let generator = AssetsGenerator(inputPath: options.inputPath)
			generator.generate(
				outputPath: options.outputPath,
				resourcesPath: options.resourcesPath,
				codeGen: options.codeGeneration
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
				codeGen: options.codeGeneration,
				path: options.outputPath
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
			let generator = SeedGenerator(
				inputPath: options.inputPath,
				langs: options.langsValue
			)
			generator.generateSeed(path: options.outputPath)
			print("Seed strings generated successfully!")
		}
	}
}
