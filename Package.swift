// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AssetsGen",
	products: [
		.executable(
			name: "assetsGen",
			targets: ["AssetsGen"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
		.package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.44.0"),
		.package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.9.0"),
	],
	targets: [
		.target(
			name: "AssetsGen",
			dependencies: ["SPMUtility", "SwiftFormat", "XMLCoder"]
		),
	]
)
