import SwiftUI

struct RingSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    private struct Style {
        static let offset: Double = 90
    }
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle - .degrees(Style.offset),
                    endAngle: endAngle - .degrees(Style.offset),
                    clockwise: false)
        return path
    }
}