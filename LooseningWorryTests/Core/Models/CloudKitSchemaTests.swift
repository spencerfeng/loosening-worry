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

        #expect(names == ["LoopOption", "Loop", "ToolSession", "LessonProgress", "KeptPhrase", "CheckIn"])
    }

    /// Synced records keep their attributes' names, so once released, renaming one would leave every earlier answer
    /// behind.
    @Test
    func `a tool session stores its tool and outcome by id`() throws {
        let session = try #require(AppModelContainer.schema.entities.first { $0.name == "ToolSession" })

        #expect(Set(session.attributes.map(\.name)).isSuperset(of: ["toolID", "outcomeID"]))
    }

    @Test
    func `a loop stores when it was noticed by id`() throws {
        let loop = try #require(AppModelContainer.schema.entities.first { $0.name == "Loop" })

        #expect(loop.attributes.map(\.name).contains("noticedID"))
    }
}
