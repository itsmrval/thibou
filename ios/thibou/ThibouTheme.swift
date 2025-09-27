import SwiftUI

struct ThibouTheme {

    struct Colors {
        static let leafGreen = Color(red: 0.6, green: 0.8, blue: 0.4)
        static let skyBlue = Color(red: 0.5, green: 0.8, blue: 0.9)
        static let creamWhite = Color(red: 0.98, green: 0.97, blue: 0.94)
        static let warmYellow = Color(red: 1.0, green: 0.9, blue: 0.6)
        static let softPink = Color(red: 0.98, green: 0.8, blue: 0.85)
        static let coral = Color(red: 1.0, green: 0.7, blue: 0.6)
        static let lavender = Color(red: 0.85, green: 0.8, blue: 0.95)

        static let backgroundGradient = LinearGradient(
            colors: [Color.clear, leafGreen.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    struct Typography {
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let mediumTitle = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let subheadline = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let callout = Font.system(size: 14, weight: .medium, design: .rounded)
        static let boldCallout = Font.system(size: 14, weight: .semibold, design: .rounded)
        static let footnote = Font.system(size: 11, weight: .regular, design: .rounded)
        static let largeTitle = Font.system(size: 24, weight: .bold, design: .rounded)
        static let smallCaption = Font.system(size: 10, weight: .medium, design: .rounded)
        static let systemBody = Font.system(size: 16, weight: .medium)
        static let systemCaption = Font.system(size: 12, weight: .medium)
        static let systemCallout = Font.system(size: 14, weight: .medium)
    }
}