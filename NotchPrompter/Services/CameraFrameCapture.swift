import AVFoundation
import AppKit
import CoreImage
import Foundation
import SwiftUI

enum PolaroidFont {
    private static let candidates = ["Bradley Hand", "Snell Roundhand", "Noteworthy", "Chalkboard SE"]

    static func handwritten(size: CGFloat) -> Font {
        for name in candidates {
            if NSFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }
        return .system(size: size, design: .serif)
    }

    static func nsFont(size: CGFloat) -> NSFont {
        for name in candidates {
            if let font = NSFont(name: name, size: size) {
                return font
            }
        }
        return NSFont.systemFont(ofSize: size)
    }
}

final class CameraFrameCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let lock = NSLock()
    private var latestSampleBuffer: CMSampleBuffer?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        lock.lock()
        latestSampleBuffer = sampleBuffer
        lock.unlock()
    }

    func makeSnapshot(mirrored: Bool) -> NSImage? {
        lock.lock()
        let sampleBuffer = latestSampleBuffer
        lock.unlock()

        guard let sampleBuffer,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        var image = CIImage(cvPixelBuffer: pixelBuffer)
        if mirrored {
            image = image
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                .transformed(by: CGAffineTransform(translationX: image.extent.width, y: 0))
        }

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            return nil
        }

        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
    }
}

enum PolaroidComposer {
    static func photoTimestamp(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }

    static func compose(
        from photo: NSImage,
        caption: String,
        capturedAt: Date,
        photoWidth: CGFloat,
        photoIsCircular: Bool = false,
        stickers: [PolaroidSticker] = []
    ) -> NSImage {
        let aspect = photo.size.height / max(photo.size.width, 1)
        let targetPhotoWidth = photoWidth
        let photoHeight = targetPhotoWidth * min(aspect, PolaroidLayout.photoAspect + 0.1)

        let sideBorder: CGFloat = PolaroidLayout.border
        let topBorder: CGFloat = PolaroidLayout.border
        let bottomBorder: CGFloat = PolaroidLayout.captionHeight + PolaroidLayout.border + 6
        let canvasWidth = targetPhotoWidth + sideBorder * 2
        let canvasHeight = topBorder + photoHeight + bottomBorder

        let composed = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight))
        composed.lockFocus()

        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)).fill()

        let photoRect = NSRect(
            x: sideBorder,
            y: bottomBorder,
            width: targetPhotoWidth,
            height: photoHeight
        )

        if photoIsCircular {
            let diameter = targetPhotoWidth
            let circleRect = NSRect(
                x: photoRect.midX - diameter / 2,
                y: photoRect.midY - diameter / 2,
                width: diameter,
                height: diameter
            )
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(ovalIn: circleRect).addClip()
            drawAspectFill(photo, in: circleRect)
            NSGraphicsContext.restoreGraphicsState()
        } else {
            photo.draw(in: photoRect, from: .zero, operation: .sourceOver, fraction: 1)
        }

        let timestamp = photoTimestamp(at: capturedAt)
        let timestampFont = NSFont.monospacedSystemFont(ofSize: 9, weight: .semibold)
        let timestampShadow = NSShadow()
        timestampShadow.shadowColor = NSColor.black.withAlphaComponent(0.75)
        timestampShadow.shadowOffset = NSSize(width: 0, height: -1)
        timestampShadow.shadowBlurRadius = 1
        let timestampAttrs: [NSAttributedString.Key: Any] = [
            .font: timestampFont,
            .foregroundColor: NSColor(red: 1, green: 0.82, blue: 0.35, alpha: 1),
            .shadow: timestampShadow,
        ]
        let timestampSize = (timestamp as NSString).size(withAttributes: timestampAttrs)
        let timestampPoint = NSPoint(
            x: photoRect.maxX - timestampSize.width - 6,
            y: photoRect.minY + 6
        )
        (timestamp as NSString).draw(at: timestampPoint, withAttributes: timestampAttrs)

        if !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let fontSize = PolaroidLayout.captionFontSize(for: targetPhotoWidth)
            let font = PolaroidFont.nsFont(size: fontSize)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black,
                .paragraphStyle: paragraph,
            ]

            let captionRect = NSRect(
                x: sideBorder + 4,
                y: 12,
                width: targetPhotoWidth - 8,
                height: bottomBorder - 16
            )
            (caption as NSString).draw(
                with: captionRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes
            )
        }

        let scaleFactor = targetPhotoWidth / 320
        for sticker in stickers {
            let fontSize = PolaroidLayout.baseStickerFontSize * sticker.scale * scaleFactor
            let font = NSFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let measured = (sticker.emoji as NSString).size(withAttributes: attributes)
            let centerX = sticker.x * canvasWidth
            let centerY = canvasHeight - (sticker.y * canvasHeight)
            let drawPoint = NSPoint(
                x: centerX - measured.width / 2,
                y: centerY - measured.height / 2
            )
            (sticker.emoji as NSString).draw(at: drawPoint, withAttributes: attributes)
        }

        composed.unlockFocus()
        return composed
    }

    private static func drawAspectFill(_ image: NSImage, in bounds: NSRect) {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let scale = max(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let drawSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = NSRect(
            x: bounds.midX - drawSize.width / 2,
            y: bounds.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
    }
}

enum ScreenshotFolder {
    static var url: URL {
        if let domain = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture"),
           let location = domain["location"] as? String,
           !location.isEmpty {
            return URL(fileURLWithPath: location, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop", isDirectory: true)
    }

    static func savePNG(_ image: NSImage, prefix: String = "Polaroid") throws -> URL {
        let folder = url
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let filename = "\(prefix) \(formatter.string(from: Date())).png"
        let destination = folder.appendingPathComponent(filename)

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            throw PolaroidSaveError.encodingFailed
        }

        try png.write(to: destination)
        return destination
    }
}

enum PolaroidSaveError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Could not save the Polaroid photo."
        }
    }
}
