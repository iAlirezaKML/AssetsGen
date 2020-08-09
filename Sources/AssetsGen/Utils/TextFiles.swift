import Foundation
import DeepDiff

class TextFile: TextOutputStream {
	let fileName: String
	
	init(fileName: String) {
		self.fileName = fileName
	}
	
	func write(_ string: String) {
		let path = Configs.outputPath / fileName
		FileUtils.makeSurePathExists(at: path)
		let log = URL(fileURLWithPath: path)
		
		do {
			let handle = try FileHandle(forWritingTo: log)
			handle.seekToEndOfFile()
			handle.write(string.data(using: .utf8)!)
			handle.closeFile()
		} catch {
			print(error.localizedDescription)
			do {
				try string.data(using: .utf8)?.write(to: log)
			} catch {
				print(error.localizedDescription)
			}
		}
	}
	
	func batchWrite(_ strings: [String]) {
		write(strings.joined())
	}
}

class CSVFile: TextFile {
	override init(fileName: String) {
		super.init(fileName: fileName + ".csv")
	}
	
	func join(_ values: [String]) -> String {
		values.joined(separator: ",") + "\n"
	}
	
	func escape(_ content: String?) -> String {
		"\"\(content ?? "")\""
	}
}

final class ParseReplacesFile: CSVFile {
	static let shared = ParseReplacesFile()
	
	private init() {
		super.init(fileName: "Replaces")
		write(join([
			"index",
			"key",
			"oldValue",
			"newValue",
		]))
	}
	
	func string(_ item: Replace<StringsSource.StringItem>) -> String {
		join([
			String(item.index),
			item.oldItem.key,
			escape(item.oldItem.value(for: Configs.baseLang, with: Configs.os)?.localizableValue),
			escape(item.newItem.value(for: Configs.baseLang, with: Configs.os)?.localizableValue),
		])
	}
	
	func write(_ items: [Replace<StringsSource.StringItem>]) {
		batchWrite(items.map { string($0) })
	}
}

final class ParseInsertsFile: CSVFile {
	static let shared = ParseInsertsFile()
	
	private init() {
		super.init(fileName: "Inserts")
		write(join([
			"index",
			"key",
			"value",
		]))
	}
	
	func string(_ item: Insert<StringsSource.StringItem>) -> String {
		join([
			String(item.index),
			item.item.key,
			escape(item.item.value(for: Configs.baseLang, with: Configs.os)?.localizableValue),
		])
	}
	
	func write(_ items: [Insert<StringsSource.StringItem>]) {
		batchWrite(items.map { string($0) })
	}
}

final class ParseDeletesFile: CSVFile {
	static let shared = ParseDeletesFile()
	
	private init() {
		super.init(fileName: "Deletes")
		write(join([
			"index",
			"key",
			"value",
		]))
	}
	
	func string(_ item: Delete<StringsSource.StringItem>) -> String {
		join([
			String(item.index),
			item.item.key,
			escape(item.item.value(for: Configs.baseLang, with: Configs.os)?.localizableValue),
		])
	}
	
	func write(_ items: [Delete<StringsSource.StringItem>]) {
		batchWrite(items.map { string($0) })
	}
}

final class ParseMovesFile: CSVFile {
	static let shared = ParseMovesFile()
	
	private init() {
		super.init(fileName: "Moves")
		write(join([
			"fromIndex",
			"toIndex",
			"key",
			"value",
		]))
	}
	
	func string(_ item: Move<StringsSource.StringItem>) -> String {
		join([
			String(item.fromIndex),
			String(item.toIndex),
			item.item.key,
			escape(item.item.value(for: Configs.baseLang, with: Configs.os)?.localizableValue),
		])
	}
	
	func write(_ items: [Move<StringsSource.StringItem>]) {
		batchWrite(items.map { string($0) })
	}
}

final class ParseXLIFFFile: CSVFile {
	static let shared = ParseXLIFFFile()
	
	private init() {
		super.init(fileName: "ParseXLIFFReconciliation")
		write(join([
			"key",
			"jsonBaseValue",
			"translatedBaseValue",
		]))
	}
	
	func write(key: String, base: String, translated: String) {
		write(join([
			key,
			escape(base),
			escape(translated),
		]))
	}
}

final class DuplicateValuesFile: CSVFile {
	static let shared = DuplicateValuesFile()
	
	private init() {
		super.init(fileName: "DuplicateValuesFile")
		write(join([
			"source",
			"value",
			"duplicatedKeys",
		]))
	}
	
	func write(source: String, value: String, duplicatedKeys: [String]) {
		write(join([
			source,
			value,
			escape(duplicatedKeys.joined(separator: ";")),
		]))
	}
}

final class DuplicateKeysFile: CSVFile {
	static let shared = DuplicateKeysFile()
	
	private init() {
		super.init(fileName: "DuplicateKeysFile")
		write(join([
			"source",
			"key"
		]))
	}
	
	func write(source: String, key: String) {
		write(join([
			source,
			key
		]))
	}
}
