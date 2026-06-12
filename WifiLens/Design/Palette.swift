import SwiftUI
import UIKit

enum Palette {
    static let accent = Color.blue
    static let success = Color.green

    static let secondaryButton = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x36 / 255, green: 0x41 / 255, blue: 0x53 / 255, alpha: 1)
            : UIColor(red: 0xE5 / 255, green: 0xE7 / 255, blue: 0xEB / 255, alpha: 1)
    })

    static let cancelButton = Color.white.opacity(0.2)
    static let overlay = Color.black.opacity(0.55)
    static let dim = Color.black.opacity(0.5)
    static let successTint = Color.green.opacity(0.12)
    static let cardFill = Color(.systemBackground)
    static let sheetSurface = Color(.systemGray6).opacity(0.95)
    static let handle = Color.secondary.opacity(0.4)

    static let scanLine = Color.cyan
    static let scanLineSoft = Color.cyan.opacity(0.9)
    static let scanLineGlow = Color.cyan.opacity(0.5)
}
