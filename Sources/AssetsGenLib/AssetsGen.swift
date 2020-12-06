import ArgumentParser

public struct AssetsGen: ParsableCommand {
	@OptionGroup()
	var options: Options
	
	public init() {}

	public static let configuration = CommandConfiguration(
		commandName: "assetsGen",
		abstract: "A Utility to Parse/Generate iOS/Android Assets(Strings/Images)",
		version: "0.4.4",
		subcommands: [
			GenerateImages.self,
			AnalyzeStrings.self,
			GenerateStrings.self,
			GenerateTranslations.self,
			ParseTranslations.self,
			GenerateSeedStrings.self,
			ParseXMLStrings.self,
		]
	)
}
