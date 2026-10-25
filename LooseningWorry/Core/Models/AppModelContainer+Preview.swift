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
        let trigger: StarterID
        let behavior: StarterID
        let result: StarterID

        init(hoursAgo: Double, _ trigger: StarterID, _ behavior: StarterID, _ result: StarterID) {
            self.hoursAgo = hoursAgo
            self.trigger = trigger
            self.behavior = behavior
            self.result = result
        }
    }

    private enum PreviewData {
        /// A week of loops, newest first.
        private static let loops: [SampleLoop] = [
            SampleLoop(hoursAgo: 1, .work, .overthought, .moreWorry),
            SampleLoop(hoursAgo: 5, .news, .scrolled, .tenseAndTired),
            SampleLoop(hoursAgo: 20, .deadline, .overPrepared, .actuallyHelped),
            SampleLoop(hoursAgo: 28, .tryingToSleep, .keptChecking, .tenseAndTired),
            SampleLoop(hoursAgo: 45, .familyOrPartner, .avoidedIt, .nothingChanged),
            SampleLoop(hoursAgo: 52, .socialPlans, .askedForReassurance, .littleRelief),
            SampleLoop(hoursAgo: 70, .money, .searchedOnline, .moreWorry),
            SampleLoop(hoursAgo: 95, .health, .searchedOnline, .notSure),
            SampleLoop(hoursAgo: 100, .waitingForReply, .keptChecking, .littleRelief),
            SampleLoop(hoursAgo: 120, .work, .overthought, .tenseAndTired),
            SampleLoop(hoursAgo: 140, .tryingToSleep, .scrolled, .nothingChanged),
            SampleLoop(hoursAgo: 160, .deadline, .putItOff, .littleRelief),
        ]

        static func insert(into context: ModelContext) {
            let newestFirst = loops.map { sample in
                let loop = Loop(
                    trigger: choice(of: sample.trigger),
                    behavior: choice(of: sample.behavior),
                    result: choice(of: sample.result),
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
            context.insert(LoopOption(overriding: .news, label: "World news"))
            let hidden = LoopOption(overriding: .snacked, label: label(of: .snacked))
            hidden.isHidden = true
            context.insert(hidden)
        }

        private static func hoursAgo(_ hours: Double) -> Date {
            Date.now.addingTimeInterval(-hours * 60 * 60)
        }

        private static func label(of starter: StarterID) -> String {
            StarterOption.with(id: starter).text
        }

        private static func choice(of starter: StarterID) -> OptionChoice {
            OptionChoice(starter, label: label(of: starter))
        }
    }
#endif
