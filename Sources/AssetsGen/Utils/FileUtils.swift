import Foundation

public struct FileUtils {
	public static func data(atPath path: String) -> Data? {
		FileManager.default.contents(atPath: path)
	}

	public static func value<T: Decodable>(atPath path: String) -> T? {
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

	public static func remove(atPath path: String) {
		do {
			try FileManager.default.removeItem(atPath: path)
		} catch {
			print("Removing failed with error:")
			print(error)
		}
	}

	public static func save(contents: String, inPath path: String) {
		if !FileManager.default.fileExists(atPath: path) {
			do {
				let url = URL(fileURLWithPath: path)
				try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
				try FileManager.default.removeItem(atPath: path)
			} catch {
				print("Creating missing directories failed with error:")
				print(error)
			}
		}
		if !FileManager.default.createFile(
			atPath: path,
			contents: contents.data(using: .utf8)
			//			,
			//			attributes: [.immutable: true]
		) {
			print("Saving file at path \(path) failed")
		}
	}

	public static func save(contentsJSON: ContentsJSON, inPath path: String) {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		do {
			let jsonData = try encoder.encode(contentsJSON)
			if let jsonString = String(data: jsonData, encoding: .utf8) {
				save(contents: jsonString, inPath: path)
			}
		} catch {
			print("Encoding json failed with error:")
			print(error)
		}
	}

	public static func copy(from source: String, to destination: String) {
		do {
			try FileManager.default.copyItem(atPath: source, toPath: destination)
		} catch {
			print("Copying failed with error:")
			print(error)
		}
	}

	public static func swiftFileName(from name: String) -> String {
		"\(name).generated.swift"
	}

	public static func xcassetsFileName(from name: String) -> String {
		"\(name.capitalized).xcassets"
	}
}
