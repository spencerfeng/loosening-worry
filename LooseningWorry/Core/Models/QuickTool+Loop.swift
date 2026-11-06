import Foundation

/// A tool met the urge in place of a habit, so a loop saved from "Nothing yet, I'm in it now" has the tool as its
/// behavior and the finish screen's answer as its result.
///
/// The ids are what a loop stores, so they never change once released. They're kept apart from the starters' ids,
/// so a tool is never counted as one of the habits the logger offers.
extension QuickTool {
    /// What every tool's behavior id starts with, so a store query can tell tools from habits.
    static let behaviorIDPrefix = "tool."

    /// The tool a loop's behavior id names, or `nil` for a habit.
    init?(behaviorID: String) {
        guard behaviorID.hasPrefix(Self.behaviorIDPrefix) else { return nil }
        self.init(rawValue: String(behaviorID.dropFirst(Self.behaviorIDPrefix.count)))
    }

    var asBehavior: OptionChoice {
        let label = switch self {
        case .curious: LocalizedStringResource("loop.tool.curious", defaultValue: "Got curious")
        case .breathe: LocalizedStringResource("loop.tool.breathe", defaultValue: "Breathed")
        case .noteIt: LocalizedStringResource("loop.tool.noteIt", defaultValue: "Noted it")
        case .beKind: LocalizedStringResource("loop.tool.beKind", defaultValue: "Was kind to myself")
        }
        return OptionChoice(id: Self.behaviorIDPrefix + rawValue, label: String(localized: label))
    }
}

extension ToolOutcome {
    /// The finish screen's word for the answer, which a loop's result shows too.
    var label: LocalizedStringResource {
        switch self {
        case .lighter: LocalizedStringResource("tool.feeling.lighter", defaultValue: "Lighter")
        case .same: LocalizedStringResource("tool.feeling.same", defaultValue: "About the same")
        case .heavier: LocalizedStringResource("tool.feeling.heavier", defaultValue: "Heavier")
        }
    }

    private static let resultIDPrefix = "outcome."

    /// The answer a loop's result id names, or `nil` for any other result, "Not sure" included.
    init?(resultID: String) {
        guard resultID.hasPrefix(Self.resultIDPrefix) else { return nil }
        self.init(rawValue: String(resultID.dropFirst(Self.resultIDPrefix.count)))
    }

    var asResult: OptionChoice {
        OptionChoice(id: Self.resultIDPrefix + rawValue, label: String(localized: label))
    }
}

extension Loop {
    /// The tool the person met the urge with, for a loop saved from "Nothing yet"; `nil` for a habit that ran.
    var metWithTool: QuickTool? {
        QuickTool(behaviorID: behaviorID)
    }
}
