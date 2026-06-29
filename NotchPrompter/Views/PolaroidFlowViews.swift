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
    let capturedAt: Date
    let photoIsCircular: Bool
    var caption: String
    var isEditingCaption = false
    var ejectProgress: CGFloat = 0
    var stickers: [PolaroidSticker] = []
    var selectedStickerID: UUID?
}

enum PolaroidEjectDirection {
    /// Rectangle mode: card rises from below the video fold (negative Y offset).
    case overlayUp
    /// Circle mode: card drops from above into the slot below the circle.
    case circleTopDown
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

    static func captionFontSize(for cardWidth: CGFloat) -> CGFloat {
        min(34, max(28, cardWidth * 0.1))
    }
}

struct PolaroidCardView: View {
    let photo: NSImage
    let cardWidth: CGFloat
    let capturedAt: Date
    let photoIsCircular: Bool
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    @Binding var stickers: [PolaroidSticker]
    @Binding var selectedStickerID: UUID?

    private var photoHeight: CGFloat { cardWidth * PolaroidLayout.photoAspect }
    private var cardContentSize: CGSize { PolaroidLayout.cardContentSize(for: cardWidth) }
    private var circularPhotoDiameter: CGFloat { cardWidth }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    photoArea

                    Text(PolaroidComposer.photoTimestamp(at: capturedAt))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 1, green: 0.82, blue: 0.35))
                        .shadow(color: .black.opacity(0.75), radius: 1, x: 0, y: 1)
                        .padding(6)
                        .allowsHitTesting(false)
                }
                .frame(width: cardWidth, height: photoHeight)

                Color.clear
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
            .zIndex(1)

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: PolaroidLayout.border + photoHeight)
                    .allowsHitTesting(false)

                captionArea
                    .frame(width: cardWidth, height: PolaroidLayout.captionHeight)

                Color.clear
                    .frame(height: PolaroidLayout.border + 6)
                    .allowsHitTesting(false)
            }
            .frame(width: cardContentSize.width, height: cardContentSize.height)
            .zIndex(2)
        }
        .frame(width: cardContentSize.width, height: cardContentSize.height)
        .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
    }

    @ViewBuilder
    private var photoArea: some View {
        let tapHandler = {
            selectedStickerID = nil
            isEditingCaption = false
        }

        if photoIsCircular {
            ZStack {
                Color.white
                Image(nsImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: circularPhotoDiameter, height: circularPhotoDiameter)
                    .clipShape(Circle())
            }
            .frame(width: cardWidth, height: photoHeight)
            .contentShape(Rectangle())
            .onTapGesture(perform: tapHandler)
        } else {
            Image(nsImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: photoHeight)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture(perform: tapHandler)
        }
    }

    private var captionArea: some View {
        PolaroidCaptionEditor(
            text: $caption,
            isEditing: $isEditingCaption,
            fontSize: PolaroidLayout.captionFontSize(for: cardWidth)
        )
        .padding(.horizontal, 4)
    }
}

enum PolaroidEmojiLibrary {
    enum Category: String, CaseIterable, Identifiable {
        case recents
        case smileys
        case animals
        case food
        case activities
        case travel
        case objects
        case symbols
        case flags

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .recents: return "clock"
            case .smileys: return "face.smiling"
            case .animals: return "dog"
            case .food: return "fork.knife"
            case .activities: return "sportscourt"
            case .travel: return "car"
            case .objects: return "lightbulb"
            case .symbols: return "heart"
            case .flags: return "flag"
            }
        }
    }

    struct Entry: Identifiable {
        let emoji: String
        let keywords: [String]
        let category: Category

        var id: String { emoji }

        init(emoji: String, keywords: [String], category: Category = .symbols) {
            self.emoji = emoji
            self.keywords = keywords
            self.category = category
        }
    }

    static var all: [Entry] { PolaroidEmojiData.all }

    static func entries(for category: Category) -> [Entry] {
        all.filter { $0.category == category }
    }

    static func matches(_ entry: Entry, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if entry.emoji.contains(q) { return true }
        return entry.keywords.contains { keyword in
            keyword.contains(q) || q.contains(keyword)
        }
    }
}

struct PolaroidEmojiSearchPicker: View {
    let onPick: (String) -> Void

    @AppStorage("polaroidEmojiRecents") private var recentsStorage = ""
    @State private var query = ""
    @State private var selectedCategory: PolaroidEmojiLibrary.Category = .recents

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 8)

    private var recents: [String] {
        recentsStorage.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    private var results: [PolaroidEmojiLibrary.Entry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return PolaroidEmojiLibrary.all.filter { PolaroidEmojiLibrary.matches($0, query: trimmed) }
        }
        if selectedCategory == .recents {
            let lookup = Dictionary(uniqueKeysWithValues: PolaroidEmojiLibrary.all.map { ($0.emoji, $0) })
            return recents.compactMap { lookup[$0] }
        }
        return PolaroidEmojiLibrary.entries(for: selectedCategory)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $query)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(white: 0.22), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 8)

            ScrollView {
                if results.isEmpty {
                    Text(selectedCategory == .recents ? "No recent emojis" : "No emojis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(results) { entry in
                            Button {
                                recordRecent(entry.emoji)
                                onPick(entry.emoji)
                            } label: {
                                Text(entry.emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
            .frame(height: 300)

            Divider().opacity(0.35)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(PolaroidEmojiLibrary.Category.allCases) { category in
                        Button {
                            selectedCategory = category
                            query = ""
                        } label: {
                            Image(systemName: category.systemImage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(selectedCategory == category ? .primary : .secondary)
                                .frame(width: 32, height: 28)
                                .background(
                                    selectedCategory == category
                                        ? Color.white.opacity(0.18)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .frame(width: 340)
        .background(Color(white: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear(perform: applyDefaultCategory)
    }

    private func applyDefaultCategory() {
        selectedCategory = recents.isEmpty ? .smileys : .recents
    }

    private func recordRecent(_ emoji: String) {
        var updated = recents.filter { $0 != emoji }
        updated.insert(emoji, at: 0)
        recentsStorage = updated.prefix(32).joined(separator: "|")
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

    private var slotHeight: CGFloat {
        PolaroidLayout.slotHeight(for: capture.cardWidth)
    }

    var body: some View {
        VStack(spacing: 10) {
            PolaroidCardView(
                photo: capture.photo,
                cardWidth: capture.cardWidth,
                capturedAt: capture.capturedAt,
                photoIsCircular: capture.photoIsCircular,
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
                    PolaroidEmojiSearchPicker { emoji in
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
        .frame(height: slotHeight, alignment: .top)
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
        case .circleTopDown:
            // Start tucked above the slot, drop down into place.
            let hidden = -(totalHeight - peek)
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
