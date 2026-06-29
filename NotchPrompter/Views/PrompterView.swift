import AppKit
import SwiftUI

private extension Color {
    static let prompterEmber = Color(red: 0.93, green: 0.35, blue: 0.10)
}

struct PrompterView: View {
    @Bindable var interaction: PrompterInteractionState
    let text: String
    let fontSize: Double
    let textColor: Color
    let offset: CGFloat
    let highlightedWordIndices: Set<Int>
    let smallCapsWordIndices: Set<Int>
    let wordCapsDisplayRevision: Int
    var onContentHeightChange: ((CGFloat, CGFloat) -> Void)?
    var onLineLayoutChange: (([PrompterLine], CGFloat, CGFloat) -> Void)?
    var onManualScroll: ((CGFloat) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let contentHeight = measuredContentHeight(width: proxy.size.width, viewportHeight: proxy.size.height)
            let lines = PrompterLineLayout.computeLines(
                text: text,
                fontSize: fontSize,
                containerWidth: proxy.size.width
            )
            let tokens = PrompterTextTokenizer.tokens(from: text)

            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .center, spacing: 0) {
                        Spacer().frame(height: PrompterTextMetrics.topPadding)
                        Text(scriptAttributedString(tokens: tokens))
                            .multilineTextAlignment(.center)
                            .lineSpacing(PrompterTextMetrics.lineSpacing)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, PrompterTextMetrics.horizontalPadding)
                            .id("caps-\(wordCapsDisplayRevision)-pulse-\(interaction.pulseWordIndex ?? -1)-\(interaction.pulseAmount)")
                        Spacer().frame(height: proxy.size.height)
                    }
                    .offset(y: -offset)
                }
                .allowsHitTesting(false)
            }
            .overlay {
                PrompterTextAreaCaptureView(
                    onScroll: { delta in onManualScroll?(delta) },
                    onClick: { location in
                        interaction.handleClick(at: location)
                    }
                )
            }
            .onAppear {
                syncInteractionState(width: proxy.size.width)
                PrompterClickRouter.shared.interactionState = interaction
                reportLayout(width: proxy.size.width, viewportHeight: proxy.size.height, contentHeight: contentHeight, lines: lines)
            }
            .onDisappear {
                if PrompterClickRouter.shared.interactionState === interaction {
                    PrompterClickRouter.shared.interactionState = nil
                }
            }
            .onChange(of: text) { _, _ in
                syncInteractionState(width: proxy.size.width)
                reportLayout(
                    width: proxy.size.width,
                    viewportHeight: proxy.size.height,
                    contentHeight: measuredContentHeight(width: proxy.size.width, viewportHeight: proxy.size.height),
                    lines: PrompterLineLayout.computeLines(text: text, fontSize: fontSize, containerWidth: proxy.size.width)
                )
            }
            .onChange(of: fontSize) { _, _ in
                syncInteractionState(width: proxy.size.width)
                reportLayout(
                    width: proxy.size.width,
                    viewportHeight: proxy.size.height,
                    contentHeight: measuredContentHeight(width: proxy.size.width, viewportHeight: proxy.size.height),
                    lines: PrompterLineLayout.computeLines(text: text, fontSize: fontSize, containerWidth: proxy.size.width)
                )
            }
            .onChange(of: offset) { _, _ in
                syncInteractionState(width: proxy.size.width)
                onLineLayoutChange?(lines, proxy.size.width, proxy.size.height)
            }
            .onChange(of: proxy.size) { _, _ in
                syncInteractionState(width: proxy.size.width)
                reportLayout(
                    width: proxy.size.width,
                    viewportHeight: proxy.size.height,
                    contentHeight: measuredContentHeight(width: proxy.size.width, viewportHeight: proxy.size.height),
                    lines: PrompterLineLayout.computeLines(text: text, fontSize: fontSize, containerWidth: proxy.size.width)
                )
            }
            .onChange(of: wordCapsDisplayRevision) { _, _ in
                reportLayout(
                    width: proxy.size.width,
                    viewportHeight: proxy.size.height,
                    contentHeight: measuredContentHeight(width: proxy.size.width, viewportHeight: proxy.size.height),
                    lines: PrompterLineLayout.computeLines(text: text, fontSize: fontSize, containerWidth: proxy.size.width)
                )
            }
        }
    }

    private func syncInteractionState(width: CGFloat) {
        interaction.text = text
        interaction.fontSize = fontSize
        interaction.containerWidth = width
        interaction.scrollOffset = offset
    }

    private func reportLayout(width: CGFloat, viewportHeight: CGFloat, contentHeight: CGFloat, lines: [PrompterLine]) {
        onContentHeightChange?(contentHeight, viewportHeight)
        onLineLayoutChange?(lines, width, viewportHeight)
    }

    private func scriptAttributedString(tokens: [PrompterWordToken]) -> AttributedString {
        tokens.reduce(into: AttributedString()) { result, token in
            switch token.kind {
            case .whitespace:
                var segment = AttributedString(token.text)
                segment.font = .system(size: fontSize, weight: .medium, design: .rounded)
                segment.foregroundColor = textColor
                result.append(segment)
            case .word(let index):
                let isHighlighted = highlightedWordIndices.contains(index)
                let emphasized = smallCapsWordIndices.contains(index)
                let display = PrompterWordDisplay.text(for: token.text, emphasized: emphasized)
                let size = isHighlighted ? fontSize + 2 : fontSize
                var segment = AttributedString(display)
                segment.font = .system(
                    size: size,
                    weight: isHighlighted || emphasized ? .semibold : .medium,
                    design: .rounded
                )
                segment.foregroundColor = textColor
                if interaction.pulseWordIndex == index {
                    segment.backgroundColor = Color.prompterEmber.opacity(0.22 + 0.58 * interaction.pulseAmount)
                }
                result.append(segment)
            }
        }
    }

    private func measuredContentHeight(width: CGFloat, viewportHeight: CGFloat) -> CGFloat {
        let lines = PrompterLineLayout.computeLines(text: text, fontSize: fontSize, containerWidth: width)
        let textHeight = lines.last.map { $0.yOffset + $0.height } ?? 0
        return textHeight + PrompterTextMetrics.topPadding + viewportHeight
    }
}

struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 18
        let notchWidth = min(rect.width * 0.22, 120)
        let notchDepth: CGFloat = 14

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - notchWidth / 2, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + notchDepth),
            control: CGPoint(x: rect.midX - notchWidth * 0.15, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + notchWidth / 2, y: rect.minY),
            control: CGPoint(x: rect.midX + notchWidth * 0.15, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
