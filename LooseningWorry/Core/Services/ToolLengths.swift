import Foundation

/// The length the person last chose for each tool that offers a choice, kept on this device.
struct ToolLengths {
    let defaults: UserDefaults

    /// The app's: kept in the standard defaults.
    static var standard: ToolLengths {
        ToolLengths(defaults: .standard)
    }

    /// The length to open `tool` at: the one last chosen, if it's still offered, or the tool's own.
    func length(for tool: QuickTool) -> Duration? {
        guard
            let seconds = defaults.object(forKey: Key.seconds(of: tool)) as? Int,
            tool.lengthOptions.contains(.seconds(seconds))
        else { return tool.length }
        return .seconds(seconds)
    }

    func remember(_ length: Duration, for tool: QuickTool) {
        defaults.set(Int(length / .seconds(1)), forKey: Key.seconds(of: tool))
    }

    private enum Key {
        static func seconds(of tool: QuickTool) -> String {
            "toolLengths.\(tool.rawValue).seconds"
        }
    }
}
