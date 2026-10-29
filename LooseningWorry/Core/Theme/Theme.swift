import SwiftUI

enum Theme {
    /// The bundled Figtree weights. See ADR 0002.
    enum FontFace: String, CaseIterable, Sendable {
        case regular = "Figtree-Regular"
        case semiBold = "Figtree-SemiBold"
        case bold = "Figtree-Bold"
        case extraBold = "Figtree-ExtraBold"

        var postScriptName: String {
            rawValue
        }
    }
}

extension Theme {
    /// Semantic colour roles. Values live in the asset catalog with light and dark appearances (ADR 0001).
    enum ColorRole: CaseIterable, Sendable {
        // Neutrals
        case background, surface, surfaceSunken, surfaceInverse
        case textPrimary, textSecondary, textTertiary, textOnAccent
        case border, borderSubtle
        // Accent
        case accent, accentText, accentPressed, accentTint
        /// The lighter end of accent gradients, such as the logger's progress segments.
        case accentSoft
        /// Fills and outlines the current row of a list, paler than `accentTint`.
        case accentWash, accentBorder
        /// Tints the soft shadows under accent elements; the same blue in light and dark, used at low opacity.
        case accentShadow
        /// The dashed outline of an accent action that adds something, such as "+ Add your own".
        case accentOutline
        // Hues, named by colour, not by the tool that uses them
        case greenStrong, greenTint, greenOnTint
        case amberStrong, amberTint, amberOnTint
        case redStrong, redTint, redOnTint
        case violetStrong, violetTint, violetOnTint
        /// Brighter fills for charts and rings, which carry no text; `Strong` stays darker for icons and text
        /// (ADR 0005).
        case greenFill, amberFill
        /// The crisis-support path. Kept apart from `red` so redesigning a tool's hue never recolours it.
        case help

        var resource: ColorResource {
            switch self {
            case .background: .background
            case .surface: .surface
            case .surfaceSunken: .surfaceSunken
            case .surfaceInverse: .surfaceInverse
            case .textPrimary: .textPrimary
            case .textSecondary: .textSecondary
            case .textTertiary: .textTertiary
            case .textOnAccent: .textOnAccent
            case .border: .border
            case .borderSubtle: .borderSubtle
            case .accent: .accent
            case .accentText: .accentText
            case .accentPressed: .accentPressed
            case .accentTint: .accentTint
            case .accentSoft: .accentSoft
            case .accentWash: .accentWash
            case .accentBorder: .accentBorder
            case .accentShadow: .accentShadow
            case .accentOutline: .accentOutline
            case .greenStrong: .greenStrong
            case .greenTint: .greenTint
            case .greenOnTint: .greenOnTint
            case .amberStrong: .amberStrong
            case .amberTint: .amberTint
            case .amberOnTint: .amberOnTint
            case .redStrong: .redStrong
            case .redTint: .redTint
            case .redOnTint: .redOnTint
            case .violetStrong: .violetStrong
            case .violetTint: .violetTint
            case .violetOnTint: .violetOnTint
            case .greenFill: .greenFill
            case .amberFill: .amberFill
            case .help: .help
            }
        }
    }
}

extension Color {
    init(theme role: Theme.ColorRole) {
        self.init(role.resource)
    }
}

extension Theme {
    struct TextMetrics: Equatable, Sendable {
        let face: FontFace
        /// Point size at the default Dynamic Type setting.
        let size: CGFloat
        let scalesWith: Font.TextStyle
    }

    /// The type scale (ADR 0002). Each style is named after, and scales with, the system style of the same name.
    enum TextStyle: CaseIterable, Sendable {
        case largeTitle, title, title2, title3, headline, body, callout, subheadline, footnote, caption, caption2

        var metrics: TextMetrics {
            switch self {
            case .largeTitle: TextMetrics(face: .extraBold, size: 48, scalesWith: .largeTitle)
            case .title: TextMetrics(face: .extraBold, size: 28, scalesWith: .title)
            case .title2: TextMetrics(face: .extraBold, size: 24, scalesWith: .title2)
            case .title3: TextMetrics(face: .bold, size: 20, scalesWith: .title3)
            case .headline: TextMetrics(face: .bold, size: 17, scalesWith: .headline)
            case .body: TextMetrics(face: .regular, size: 16, scalesWith: .body)
            case .callout: TextMetrics(face: .bold, size: 15, scalesWith: .callout)
            case .subheadline: TextMetrics(face: .bold, size: 14, scalesWith: .subheadline)
            case .footnote: TextMetrics(face: .semiBold, size: 13, scalesWith: .footnote)
            case .caption: TextMetrics(face: .regular, size: 13, scalesWith: .caption)
            case .caption2: TextMetrics(face: .semiBold, size: 11, scalesWith: .caption2)
            }
        }
    }
}

extension Font {
    static func theme(_ style: Theme.TextStyle) -> Font {
        let metrics = style.metrics
        return .custom(metrics.face.postScriptName, size: metrics.size, relativeTo: metrics.scalesWith)
    }
}

extension ShapeStyle where Self == Color {
    static func theme(_ role: Theme.ColorRole) -> Color {
        Color(theme: role)
    }
}
