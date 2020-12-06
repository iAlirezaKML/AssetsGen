import Foundation

struct FileUtils {
	static func data(atPath path: String) -> Data? {
		FileManager.default.contents(atPath: path)
	}

	static func value<T: Decodable>(atPath path: String) -> T? {
		guard let data = data(atPath: path) else { return nil }
		let decoder = JSONDecoder()
		do {
			return try decoder.decode(T.self, from: data)
		} catch {
			print("Reading value of type \(T.self) failed with error:")
			print(error)
			return nil
		}
	}

	static func remove(atPath path: String) {
		guard FileManager.default.fileExists(atPath: path) else { return }
		do {
			try FileManager.default.removeItem(atPath: path)
		} catch {
			print("Removing failed with error:")
			print(error)
		}
	}
	
	static func fileExists(at path: String) -> Bool {
		FileManager.default.fileExists(atPath: path)
	}
	
	static func makeSurePathExists(at path: String) {
		if !fileExists(at: path) {
			do {
				let url = URL(fileURLWithPath: path)
				try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
				try FileManager.default.removeItem(atPath: path)
			} catch {
				print("Creating missing directories failed with error:")
				print(error)
			}
		}
	}

	static func save(contents: String, inPath path: String) {
		makeSurePathExists(at: path)
		if !FileManager.default.createFile(
			atPath: path,
			contents: contents.data(using: .utf8)
		) {
			print("Saving file at path \(path) failed")
		}
	}

	static func saveJSON<T: Encodable>(_ encodable: T, inPath path: String) {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		do {
			let jsonData = try encoder.encode(encodable)
			if let jsonString = String(data: jsonData, encoding: .utf8) {
				save(contents: jsonString, inPath: path)
			}
		} catch {
			print("Encoding json failed with error:")
			print(error)
		}
	}

	static func copy(from source: String, to destination: String) {
		do {
			try FileManager.default.copyItem(atPath: source, toPath: destination)
		} catch {
			print("Copying failed with error:")
			print(error)
		}
	}

	static func swiftFileName(from name: String) -> String {
		"\(name).generated.swift"
	}

	static func xcassetsFileName(from name: String) -> String {
		"\(name.capitalized).xcassets"
	}
	
	@discardableResult
	static func shell(_ command: String) -> String {
		let task = Process()
		let pipe = Pipe()
		
		task.standardOutput = pipe
		task.arguments = ["-c", command]
		task.launchPath = "/bin/zsh"
		task.launch()
		
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(data: data, encoding: .utf8) ?? ""
		
		return output
	}
}
