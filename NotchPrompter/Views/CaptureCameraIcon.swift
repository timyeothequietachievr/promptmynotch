import SwiftUI

/// Compact camera silhouette (body, viewfinder, lens) for the capture button.
struct CaptureCameraIcon: View {
    var body: some View {
        CaptureCameraIconShape()
            .fill(style: FillStyle(eoFill: true))
    }
}

private struct CaptureCameraIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        let viewfinder = CGRect(x: w * 0.16, y: h * 0.06, width: w * 0.30, height: h * 0.16)
        path.addRoundedRect(in: viewfinder, cornerSize: CGSize(width: w * 0.06, height: h * 0.06))

        let body = CGRect(x: w * 0.06, y: h * 0.20, width: w * 0.88, height: h * 0.62)
        path.addRoundedRect(in: body, cornerSize: CGSize(width: w * 0.14, height: h * 0.14))

        let lensRadius = w * 0.17
        let lensCenter = CGPoint(x: w * 0.54, y: h * 0.51)
        path.addEllipse(in: CGRect(
            x: lensCenter.x - lensRadius,
            y: lensCenter.y - lensRadius,
            width: lensRadius * 2,
            height: lensRadius * 2
        ))

        return path
    }
}
