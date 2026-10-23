#if DEBUG
    import SwiftUI

    /// Every colour role and text style, for comparing Theme with the design canvas. Previews only.
    private struct ThemeGallery: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Theme.TextStyle.allCases, id: \.self) { style in
                            Text(verbatim: "\(style) · \(Int(style.metrics.size))")
                                .font(.theme(style))
                        }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        ForEach(Theme.ColorRole.allCases, id: \.self) { role in
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.theme(role))
                                    .stroke(.theme(.border))
                                    .frame(height: 44)
                                Text(verbatim: "\(role)")
                                    .font(.theme(.caption2))
                            }
                        }
                    }
                }
                .foregroundStyle(.theme(.textPrimary))
                .padding(20)
            }
            .background(.theme(.background))
        }
    }

    #Preview("Light") {
        ThemeGallery()
            .preferredColorScheme(.light)
    }

    #Preview("Dark") {
        ThemeGallery()
            .preferredColorScheme(.dark)
    }
#endif
