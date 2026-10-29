import CoreGraphics
@testable import LooseningWorry
import SwiftUI
import Testing

/// Pins every colour role to its light and dark value from the design canvas (ADR 0001).
/// Changing a colour on purpose means changing the asset catalog and this table together.
struct ThemeColorTests {
    static let canvas: [Theme.ColorRole: (light: String, dark: String)] = [
        .background: ("F7F6F3", "141413"),
        .surface: ("FFFFFF", "242423"),
        .surfaceSunken: ("F2F0EC", "2E2D2B"),
        .surfaceInverse: ("1F1F1F", "3A3A38"),
        .textPrimary: ("1F1F1F", "F2F1EE"),
        .textSecondary: ("4A4744", "C9C6C0"),
        .textTertiary: ("6E6B66", "A3A09A"),
        .textOnAccent: ("FFFFFF", "FFFFFF"),
        .border: ("E6E3DE", "3A3936"),
        .borderSubtle: ("EFEDE9", "34332F"),
        .accent: ("2E6AE6", "4C82F0"),
        .accentText: ("2558C9", "8DB0F7"),
        .accentPressed: ("1D47A6", "A9C3F8"),
        .accentTint: ("E4EDFD", "1E2B47"),
        .accentSoft: ("5B8DF0", "6E99F3"),
        .accentWash: ("F1F5FE", "1A2540"),
        .accentBorder: ("C9D9FA", "2C4170"),
        .accentShadow: ("2E6AE6", "2E6AE6"),
        .accentOutline: ("9DB6EE", "4A67A8"),
        .greenStrong: ("2E8A5C", "5CC48F"),
        .greenTint: ("E3F4EA", "17322A"),
        .greenOnTint: ("1F6B45", "7FD4A6"),
        .greenFill: ("4CB782", "4CB782"),
        .amberStrong: ("B86E12", "F0B866"),
        .amberTint: ("FDF0DC", "3A2C17"),
        .amberOnTint: ("8A5210", "F0B866"),
        .amberFill: ("F0A33A", "F0A33A"),
        .redStrong: ("D9574B", "D9574B"),
        .redTint: ("FCE8E6", "3D1F1C"),
        .redOnTint: ("8C2B22", "F4ABA2"),
        .violetStrong: ("6A4FD8", "8A73EE"),
        .violetTint: ("EEE9FC", "2A2347"),
        .violetOnTint: ("5B3FC4", "B3A2F5"),
        .help: ("C2453A", "F09A90"),
    ]

    @Test
    func `every role is pinned`() {
        let unpinned = Theme.ColorRole.allCases.filter { Self.canvas[$0] == nil }
        #expect(unpinned.isEmpty, "Add these roles to the canvas table: \(unpinned)")
    }

    @Test(arguments: Array(canvas.keys))
    func `role matches canvas in light and dark`(role: Theme.ColorRole) throws {
        let expected = try #require(Self.canvas[role])
        #expect(hex(of: role, in: .light) == expected.light)
        #expect(hex(of: role, in: .dark) == expected.dark)
    }

    private func hex(of role: Theme.ColorRole, in scheme: ColorScheme) -> String? {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let resolved = Color(theme: role).resolve(in: environment)
        guard
            let srgb = CGColorSpace(name: CGColorSpace.sRGB),
            let components = resolved.cgColor.converted(to: srgb, intent: .defaultIntent, options: nil)?.components,
            components.count >= 3
        else { return nil }
        return components.prefix(3)
            .map { String(format: "%02X", Int(($0 * 255).rounded())) }
            .joined()
    }
}
