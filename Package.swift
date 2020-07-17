// swift-tools-version:5.2

import PackageDescription

let package = Package(
	name: "AssetsGen",
	platforms: [
		.macOS(.v10_14),
	],
	products: [
		.executable(
			name: "assetsGen",
			targets: ["AssetsGen"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0"),
		.package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.44.0"),
		.package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.9.0"),
		.package(url: "https://github.com/onmyway133/DeepDiff.git", from: "2.3.0"),
	],
	targets: [
		.target(
			name: "AssetsGen",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"SwiftFormat",
				"XMLCoder",
				"DeepDiff",
			]
		),
	]
)
