import CoreGraphics

enum Layout {
    // Padding / spacing
    static let screenH: CGFloat = 32
    static let cardH: CGFloat = 24
    static let descriptionH: CGFloat = 40
    static let topTitle: CGFloat = 72
    static let bottomSafe: CGFloat = 48
    static let buttonSpacing: CGFloat = 12
    static let sectionGap: CGFloat = 20
    static let rowGap: CGFloat = 16
    static let buttonPaddingV: CGFloat = 18

    // Corner radii
    static let buttonRadius: CGFloat = 14
    static let pillRadius: CGFloat = 22
    static let cardRadius: CGFloat = 24
    static let dialogRadius: CGFloat = 20
    static let viewfinderRadius: CGFloat = 16
    static let handleRadius: CGFloat = 2

    // Component sizes
    static let iconSize: CGFloat = 120
    static let viewfinderSize: CGFloat = 260
    static let cornerBracketLength: CGFloat = 28
    static let cornerBracketLineWidth: CGFloat = 4
    static let scanLineHeight: CGFloat = 3
    static let scanLineGlowRadius: CGFloat = 6
    static let scanLineGlowRadiusOuter: CGFloat = 12
    static let handleWidth: CGFloat = 36
    static let handleHeight: CGFloat = 4
    static let progressScale: CGFloat = 1.4
}

enum Motion {
    static let screenTransition: Double = 0.1
    static let statusFade: Double = 0.2
    static let keyboardLift: Double = 0.25
    static let scanLineSweep: Double = 1.8
}
