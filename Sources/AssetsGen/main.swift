do {
	let command = try Command()
	try command.run()
} catch {
	print(error)
}
