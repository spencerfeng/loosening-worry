@testable import LooseningWorry
import SwiftData
import Testing

/// CloudKit sync rejects a store whose schema breaks its rules, so every model must meet them.
struct CloudKitSchemaTests {
    @Test
    func `every model in the app schema meets CloudKit's rules`() {
        var violations: [String] = []

        for entity in AppModelContainer.schema.entities {
            for attribute in entity.attributes {
                let name = "\(entity.name).\(attribute.name)"
                if !attribute.isOptional, attribute.defaultValue == nil {
                    violations.append("\(name) needs a default or must be optional")
                }
                if attribute.isUnique {
                    violations.append("\(name) must not be unique")
                }
            }
            for relationship in entity.relationships {
                let name = "\(entity.name).\(relationship.name)"
                if !relationship.isOptional {
                    violations.append("\(name) must be optional")
                }
                if relationship.inverseName == nil {
                    violations.append("\(name) needs an inverse")
                }
            }
        }

        #expect(violations.isEmpty, "\(violations.sorted().joined(separator: "\n"))")
    }

    @Test
    func `app schema holds every model`() {
        let names = Set(AppModelContainer.schema.entities.map(\.name))

        #expect(names == ["LoopOption", "Loop", "ToolSession", "LessonProgress", "KeptPhrase"])
    }
}
