// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "AssetsGen",
	platforms: [
		.macOS(.v10_15),
	],
	products: [
		.executable(name: "assetsGen", targets: ["CommandLineTool"]),
		.library(name: "AssetsGenLib", targets: ["AssetsGenLib"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0"),
		.package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.9.0"),
		.package(url: "https://github.com/onmyway133/DeepDiff.git", from: "2.3.0"),
	],
	targets: [
		.target(
			name: "AssetsGenLib",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"XMLCoder",
				"DeepDiff",
			]
		),
		.target(name: "CommandLineTool", dependencies: ["AssetsGenLib"]),
		.testTarget(name: "AssetsGenTests", dependencies: ["AssetsGenLib"]),
	]
)
