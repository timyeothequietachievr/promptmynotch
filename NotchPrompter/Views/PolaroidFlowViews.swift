import AppKit
import SwiftUI

struct PolaroidSticker: Identifiable, Equatable {
    let id: UUID
    var emoji: String
    /// Normalized 0–1 position on the full card (top-left origin).
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat

    init(id: UUID = UUID(), emoji: String, x: CGFloat, y: CGFloat, scale: CGFloat = 1) {
        self.id = id
        self.emoji = emoji
        self.x = x
        self.y = y
        self.scale = scale
    }
}

struct PolaroidCaptureState {
    let photo: NSImage
    let cardWidth: CGFloat
    var caption: String
    var isEditingCaption = false
    var ejectProgress: CGFloat = 0
    var stickers: [PolaroidSticker] = []
    var selectedStickerID: UUID?
}

enum PolaroidEjectDirection {
    /// Rectangle mode: card rises from below the video fold (negative Y offset).
    case overlayUp
    /// Circle mode: card sits at the bottom edge — only a small offset, never pulled into the circle.
    case circleBottom
}

enum PolaroidLayout {
    static let border: CGFloat = 14
    static let captionHeight: CGFloat = 54
    static let photoAspect: CGFloat = 0.82
    static let actionsHeight: CGFloat = 52
    static let baseStickerFontSize: CGFloat = 36

    static func cardWidth(for windowWidth: CGFloat) -> CGFloat {
        max(160, windowWidth - 20)
    }

    static func cardHeight(for cardWidth: CGFloat) -> CGFloat {
        border + cardWidth * photoAspect + captionHeight + border + 6
    }

    static func cardContentSize(for cardWidth: CGFloat) -> CGSize {
        CGSize(
            width: cardWidth + border * 2,
            height: cardHeight(for: cardWidth)
        )
    }

    static func slotHeight(for cardWidth: CGFloat) -> CGFloat {
        cardHeight(for: cardWidth) + actionsHeight + 24
    }
}

struct PolaroidCardView: View {
    let photo: NSImage
    let cardWidth: CGFloat
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    @Binding var stickers: [PolaroidSticker]
    @Binding var selectedStickerID: UUID?

    private var photoHeight: CGFloat { cardWidth * PolaroidLayout.photoAspect }
    private var cardContentSize: CGSize { PolaroidLayout.cardContentSize(for: cardWidth) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Image(nsImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: photoHeight)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStickerID = nil
                        isEditingCaption = false
                    }

                captionArea
                    .frame(width: cardWidth, height: PolaroidLayout.captionHeight)
            }
            .padding(.top, PolaroidLayout.border)
            .padding(.horizontal, PolaroidLayout.border)
            .padding(.bottom, PolaroidLayout.border + 6)
            .background(Color.white)

            PolaroidStickersOverlay(
                stickers: $stickers,
                selectedStickerID: $selectedStickerID,
                cardSize: cardContentSize
            )
            .frame(width: cardContentSize.width, height: cardContentSize.height)
        }
        .frame(width: cardContentSize.width, height: cardContentSize.height)
        .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
    }

    private var captionArea: some View {
        PolaroidCaptionEditor(
            text: $caption,
            isEditing: $isEditingCaption,
            fontSize: captionFontSize
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
    }

    private var captionFontSize: CGFloat {
        cardWidth > 280 ? 16 : 14
    }
}

struct PolaroidEmojiPicker: View {
    let onPick: (String) -> Void

    private let emojis = [
        "😀", "😂", "🥰", "😎", "🤩", "😊",
        "👍", "👏", "🙌", "💪", "✌️", "🤘",
        "❤️", "🧡", "💛", "💚", "💙", "💜",
        "🔥", "✨", "⭐", "🎉", "🎊", "💯",
        "📸", "🌈", "☀️", "🌙", "⚡", "💫",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 6) {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    onPick(emoji)
                } label: {
                    Text(emoji)
                        .font(.title2)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(width: 240)
    }
}

struct PolaroidEjectStack: View {
    @Binding var capture: PolaroidCaptureState
    let onCancel: () -> Void
    let onSave: () -> Void
    var ejectDirection: PolaroidEjectDirection = .overlayUp

    @State private var showEmojiPicker = false

    private var cardHeight: CGFloat {
        PolaroidLayout.cardHeight(for: capture.cardWidth)
    }

    var body: some View {
        VStack(spacing: 10) {
            PolaroidCardView(
                photo: capture.photo,
                cardWidth: capture.cardWidth,
                caption: $capture.caption,
                isEditingCaption: $capture.isEditingCaption,
                stickers: $capture.stickers,
                selectedStickerID: $capture.selectedStickerID
            )
            .rotationEffect(.degrees(Double(1 - capture.ejectProgress) * -2.5))

            HStack(spacing: 12) {
                Button {
                    showEmojiPicker = true
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color(white: 0.15))
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: Circle())
                        .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Add emoji sticker")
                .popover(isPresented: $showEmojiPicker, arrowEdge: .bottom) {
                    PolaroidEmojiPicker { emoji in
                        addSticker(emoji)
                        showEmojiPicker = false
                    }
                }

                Spacer(minLength: 0)

                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color(white: 0.15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(Color.black.opacity(0.18), lineWidth: 1))

                Button("Save", action: onSave)
                    .buttonStyle(.plain)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
            .padding(.horizontal, 4)
        }
        .offset(y: ejectOffset)
        .onAppear {
            if capture.ejectProgress < 1 {
                runEjectAnimation()
            }
        }
    }

    private func addSticker(_ emoji: String) {
        let sticker = PolaroidSticker(emoji: emoji, x: 0.5, y: 0.38, scale: 1)
        capture.stickers.append(sticker)
        capture.selectedStickerID = sticker.id
    }

    private var ejectOffset: CGFloat {
        let peek: CGFloat = 20
        let totalHeight = cardHeight + PolaroidLayout.actionsHeight + 10

        switch ejectDirection {
        case .overlayUp:
            let hidden = -(totalHeight - peek)
            let ejected: CGFloat = 4
            return hidden + capture.ejectProgress * (ejected - hidden)
        case .circleBottom:
            // Rise up into the slot below the circle (positive offset tucks it out of view).
            let hidden = totalHeight - peek
            let ejected: CGFloat = 0
            return hidden + capture.ejectProgress * (ejected - hidden)
        }
    }

    private func runEjectAnimation() {
        withAnimation(.timingCurve(0.12, 0.0, 0.18, 1.0, duration: 2.4)) {
            capture.ejectProgress = 1
        }
    }
}

struct PolaroidDragBlockingHost<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> PolaroidDragBlockingHostingView<Content> {
        PolaroidDragBlockingHostingView(rootView: content)
    }

    func updateNSView(_ nsView: PolaroidDragBlockingHostingView<Content>, context: Context) {
        nsView.rootView = content
    }
}

final class PolaroidDragBlockingHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
