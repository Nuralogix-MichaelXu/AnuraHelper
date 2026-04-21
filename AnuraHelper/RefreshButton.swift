import SwiftUI

struct RefreshButton: View {
    @Binding var isRefreshing: Bool
    @Binding var refreshCompleted: Bool
    var requestData: () -> Void
    @State private var rotation: Double = 0
    @State private var timer: Timer? = nil
    private struct Style {
        static let ringSize: CGFloat = 40
        static let buttonSize: CGFloat = 35
        static let font = Font.system(size: 8, weight: .medium)
        static let buttonColor = Color.deepPurple
        static let shadowColor = Color.gray.opacity(0.6)
        static let shadowRadius: CGFloat = 5
        static let shadowX: CGFloat = 5
        static let shadowY: CGFloat = 5
        static let paddingTrailing: CGFloat = 20
    }
    func startRotationAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            rotation += 6
            if rotation >= 360 { rotation -= 360 }
        }
    }
    var body: some View {
        ZStack() {
            ZStack {
                RingSegment(startAngle: .degrees(0), endAngle: .degrees(110))
                    .stroke(Style.buttonColor, lineWidth: 3)
                RingSegment(startAngle: .degrees(120), endAngle: .degrees(230))
                    .stroke(Style.buttonColor, lineWidth: 3)
                RingSegment(startAngle: .degrees(240), endAngle: .degrees(350))
                    .stroke(Style.buttonColor, lineWidth: 3)
            }
            .frame(width: Style.ringSize, height: Style.ringSize)
            .rotationEffect(.degrees(rotation))
            .opacity(0.7)
            Button(action: {
                if isRefreshing { return }
                startRotationAnimation()
                requestData()
            }) {
                Text(isRefreshing ? Localized("loading") : Localized("refresh"))
                    .font(Style.font)
                    .foregroundColor(.white)
                    .frame(width: Style.buttonSize, height: Style.buttonSize)
                    .background(Style.buttonColor)
                    .clipShape(Circle())
                    .shadow(color: Style.shadowColor, radius: Style.shadowRadius, x: Style.shadowX, y: Style.shadowY)
            }
        }
        .padding(.trailing, Style.paddingTrailing)
        .onChange(of: isRefreshing) { _, refreshing in
            if refreshing {
                startRotationAnimation()
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
        .onChange(of: refreshCompleted) { _, completed in
            if completed && isRefreshing {
                timer?.invalidate()
                timer = nil
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRefreshing = false
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onAppear {
            if isRefreshing {
                startRotationAnimation()
            }
        }
    }
}