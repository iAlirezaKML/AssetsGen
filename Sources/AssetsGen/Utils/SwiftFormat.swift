import Foundation

#if os(macOS)
	import Darwin.POSIX
#else
	import Glibc
#endif

import SwiftFormat

public struct SwiftFormatter {
	private static var stderr = FileHandle.standardError

	private static let stderrIsTTY = isatty(STDERR_FILENO) != 0

	private static let printQueue = DispatchQueue(label: "swiftformat.print")

	public static func setup() {
		CLI.print = { message, type in
			printQueue.sync {
				switch type {
				case .info:
					print(message, to: &stderr)
				case .success:
					print(stderrIsTTY ? message.inGreen : message, to: &stderr)
				case .error:
					print(stderrIsTTY ? message.inRed : message, to: &stderr)
				case .warning:
					print(stderrIsTTY ? message.inYellow : message, to: &stderr)
				case .content:
					print(message)
				case .raw:
					print(message, terminator: "")
				}
			}
		}
	}

	public static func format(_ path: String) {
		let swiftformat = """
		# format options
		--indent tabs
		--tabwidth 2
		--swiftversion 5.1
		"""
		FileUtils.save(contents: swiftformat, inPath: path / ".swiftformat")
		let exitCode = SwiftFormat.CLI.run(in: FileManager.default.currentDirectoryPath, with: path)
		print(exitCode)
	}
}

extension String {
	var inDefault: String { "\u{001B}[39m\(self)" }
	var inRed: String { "\u{001B}[31m\(self)\u{001B}[0m" }
	var inGreen: String { "\u{001B}[32m\(self)\u{001B}[0m" }
	var inYellow: String { "\u{001B}[33m\(self)\u{001B}[0m" }
}

extension FileHandle: TextOutputStream {
	public func write(_ string: String) {
		write(Data(string.utf8))
	}
}
