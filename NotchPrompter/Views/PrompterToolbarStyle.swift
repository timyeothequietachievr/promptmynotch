import SwiftUI

enum PrompterToolbarStyle {
    static let circleIconSize: CGFloat = 28

    static func filledCircleIcon(
        systemName: String,
        primary: Color,
        secondary: Color = Color.white.opacity(0.28)
    ) -> some View {
        Image(systemName: systemName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(primary, secondary)
            .font(.system(size: circleIconSize))
            .frame(width: circleIconSize, height: circleIconSize)
    }

    static func mirrorFilledCircleIcon(
        systemName: String,
        primary: Color = .white,
        secondary: Color = Color.white.opacity(0.28)
    ) -> some View {
        filledCircleIcon(systemName: systemName, primary: primary, secondary: secondary)
    }

    static func editorFilledCircleIcon(systemName: String, active: Bool = false) -> some View {
        filledCircleIcon(
            systemName: systemName,
            primary: active ? .green : .primary,
            secondary: Color.primary.opacity(0.18)
        )
        .font(.system(size: 22))
        .frame(width: 28, height: 28)
    }

    static func textColorCircleIcon(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.14))
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: circleIconSize, height: circleIconSize)
        .overlay(
            Circle().stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }
}

extension View {
    func prompterToolbarFilledCircleIcon() -> some View {
        font(.system(size: PrompterToolbarStyle.circleIconSize))
            .frame(width: PrompterToolbarStyle.circleIconSize, height: PrompterToolbarStyle.circleIconSize)
    }

    func prompterToolbarCapsule(height: CGFloat = 28) -> some View {
        frame(height: height)
            .padding(.horizontal, 10)
            .background(.white.opacity(0.12), in: Capsule())
    }
}
