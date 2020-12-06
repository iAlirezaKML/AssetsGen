import Foundation

extension XMLElement {
	static func make(
		name: String,
		value: String,
		options: XMLNode.Options = [.nodeNeverEscapeContents, .nodePreserveAll],
		resolvingEntities: Bool = true
	) -> XMLElement {
		let element = XMLElement(name: name)
		let content = XMLElement(kind: .text, options: options)
		content.setStringValue(value, resolvingEntities: resolvingEntities)
		element.setChildren([content])
		return element
	}
}
