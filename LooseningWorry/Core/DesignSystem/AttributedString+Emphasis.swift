import SwiftUI

extension AttributedString {
    /// The same text with its strongly emphasized runs, the `**` parts of a localized string, set in `font` and
    /// `color` instead of bold. Used for counts that stand out within a sentence translators keep whole.
    func restylingEmphasis(font: Font, color: Color) -> AttributedString {
        var text = self
        for run in text.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            text[run.range].inlinePresentationIntent = nil
            text[run.range].font = font
            text[run.range].foregroundColor = color
        }
        return text
    }
}
