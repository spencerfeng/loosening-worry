#if DEBUG
    import Foundation

    @MainActor
    extension ToolRunViewModel {
        /// A run of `tool` for previews, saving to the preview store, never the person's data.
        static func preview(_ tool: QuickTool) -> ToolRunViewModel {
            ToolRunViewModel(
                tool: tool,
                now: .now,
                picker: .standard,
                lengths: .standard,
                sessions: SessionStore(context: AppModelContainer.preview.mainContext),
            )
        }
    }
#endif
