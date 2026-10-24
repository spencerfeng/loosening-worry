#if DEBUG
    import Foundation
    import SwiftData

    @MainActor
    extension AppModelContainer {
        /// An in-memory store filled with sample data, so every screen previews with something to show.
        static let preview: ModelContainer = {
            do {
                let container = try make(inMemory: true)
                PreviewData.insert(into: container.mainContext)
                return container
            } catch {
                fatalError("Could not open the preview store: \(error)")
            }
        }()
    }

    /// A sample loop: how long ago it was logged and the ids of the starters it used.
    private struct SampleLoop {
        let hoursAgo: Double
        let trigger: String
        let behavior: String
        let result: String

        init(hoursAgo: Double, _ trigger: String, _ behavior: String, _ result: String) {
            self.hoursAgo = hoursAgo
            self.trigger = trigger
            self.behavior = behavior
            self.result = result
        }
    }

    private enum PreviewData {
        /// A week of loops, newest first.
        private static let loops: [SampleLoop] = [
            SampleLoop(hoursAgo: 1, "trigger.workEmail", "behavior.overthinking", "result.moreWorry"),
            SampleLoop(hoursAgo: 5, "trigger.news", "behavior.scrolled", "result.tenseAndTired"),
            SampleLoop(hoursAgo: 20, "trigger.deadline", "behavior.overPlanned", "result.actualAnswer"),
            SampleLoop(hoursAgo: 28, "trigger.bedtime", "behavior.checkedPhone", "result.lostSleep"),
            SampleLoop(hoursAgo: 45, "trigger.workEmail", "behavior.avoidedIt", "result.nothingChanged"),
            SampleLoop(hoursAgo: 52, "trigger.socialPlans", "behavior.askedForReassurance", "result.littleRelief"),
            SampleLoop(hoursAgo: 70, "trigger.money", "behavior.searchedOnline", "result.moreWorry"),
            SampleLoop(hoursAgo: 95, "trigger.health", "behavior.searchedOnline", "result.restless"),
            SampleLoop(hoursAgo: 100, "trigger.waitingForReply", "behavior.checkedPhone", "result.distracted"),
            SampleLoop(hoursAgo: 120, "trigger.workEmail", "behavior.overthinking", "result.tenseAndTired"),
            SampleLoop(hoursAgo: 140, "trigger.bedtime", "behavior.scrolled", "result.lostSleep"),
            SampleLoop(hoursAgo: 160, "trigger.deadline", "behavior.snacked", "result.littleRelief"),
        ]

        static func insert(into context: ModelContext) {
            let newestFirst = loops.map { sample in
                let loop = Loop(
                    trigger: label(of: sample.trigger),
                    behavior: label(of: sample.behavior),
                    result: label(of: sample.result),
                )
                loop.createdAt = hoursAgo(sample.hoursAgo)
                context.insert(loop)
                return loop
            }

            let session = ToolSession(tool: .breathe)
            session.loop = newestFirst.first
            session.startedAt = hoursAgo(1)
            session.durationSeconds = 120
            session.feeling = .lighter
            context.insert(session)

            for day in 1 ... 3 {
                let progress = LessonProgress(day: day)
                progress.completedAt = hoursAgo(Double(4 - day) * 24)
                context.insert(progress)
            }

            context.insert(LoopOption(kind: .trigger, label: "Rent due"))
            context.insert(LoopOption(kind: .trigger, label: "World news", starterID: "trigger.news"))
            let hidden = LoopOption(
                kind: .behavior,
                label: label(of: "behavior.snacked"),
                starterID: "behavior.snacked",
            )
            hidden.isHidden = true
            context.insert(hidden)
        }

        private static func hoursAgo(_ hours: Double) -> Date {
            Date.now.addingTimeInterval(-hours * 60 * 60)
        }

        private static func label(of starterID: String) -> String {
            guard let starter = StarterOption.with(id: starterID) else {
                preconditionFailure("No starter with id \(starterID)")
            }
            return String(localized: starter.label)
        }
    }
#endif
