import SwiftUI
import Charts

struct AnalysisDayView: View {
    let data: [DayMeasurement]
    
    /// 稳定选中值（UI 展示只依赖它）
    @State private var selectedDate: Date?
    
    // 默认显示30天，可横向滚动查看更多
    @State private var visibleDomainLength: TimeInterval = 7 * 24 * 60 * 60
    @State private var scrollPosition: Date = Date()
    
    // MARK: - Zoom & Axis density
    
    private var minVisibleDays: Double { 7 }
    private var maxVisibleDays: Double { 30 }
    
    private var visibleDays: Double {
        // Convert seconds -> days
        max(minVisibleDays, min(maxVisibleDays, visibleDomainLength / (24 * 60 * 60)))
    }
    
    /// Decide x-axis label stride based on current zoom level.
    /// Smaller visible range => show daily labels; larger => show fewer.
    private var xAxisStrideDays: Int {
        switch visibleDays {
        case ..<(UIDevice.current.isIPad ? 10 : 8):
            return 1
        case ..<(UIDevice.current.isIPad ? 16 : 12):
            return 2
        case ..<(UIDevice.current.isIPad ? 25 : 20):
            return 3
        default:
            return 5
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localized("analysis_day_title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value(Localized("analysis_axis_date"), item.date),
                        y: .value(Localized("analysis_axis_measurement_count"), item.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    .lineStyle(.init(lineWidth: 2))
                    
                    PointMark(
                        x: .value(Localized("analysis_axis_date"), item.date),
                        y: .value(Localized("analysis_axis_measurement_count"), item.count)
                    )
                    .foregroundStyle(.blue)
                }
                
                if let selected = selectedDataPoint {
                    RuleMark(x: .value(Localized("analysis_selected_date"), selected.date))
                        .foregroundStyle(.gray.opacity(0.35))
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                    
                    PointMark(
                        x: .value(Localized("analysis_selected_date"), selected.date),
                        y: .value(Localized("analysis_selected_measurement_count"), selected.count)
                    )
                    .symbolSize(80)
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 260)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: visibleDomainLength)
            .chartScrollPosition(x: $scrollPosition)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStrideDays)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(Self.dayLabel(for: date))
                                .padding(.leading, -4)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            // 在 overlay 中同时处理点击、缩放和滚动
            .chartOverlay { proxy in
                GeometryReader { geo in
                    ChartOverlayView(
                        proxy: proxy,
                        plotFrame: proxy.plotFrame.map { geo[$0] },
                        data: data,
                        scrollPosition: $scrollPosition,
                        visibleDomainLength: $visibleDomainLength,
                        selectedDate: $selectedDate,
                        minVisibleDays: minVisibleDays,
                        maxVisibleDays: maxVisibleDays
                    )
                }
            }
            
            if let selected = selectedDataPoint {
                Text(String(format: Localized("analysis_selected_day_format"), Self.fullDateLabel(for: selected.date), formatCount(selected.count)))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Text(Localized("analysis_day_hint"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear {
            guard let first = data.first?.date, let last = data.last?.date else { return }
            let start = Calendar.current.date(byAdding: .day, value: -7, to: last) ?? first
            scrollPosition = max(start, first)
        }
    }
    
    private var selectedDataPoint: DayMeasurement? {
        guard let selectedDate else { return nil }
        let nearest = nearestDate(to: selectedDate)
        return data.first { Calendar.current.isDate($0.date, inSameDayAs: nearest) }
    }
    
    private func nearestDate(to rawDate: Date) -> Date {
        data.min {
            abs($0.date.timeIntervalSince(rawDate)) < abs($1.date.timeIntervalSince(rawDate))
        }?.date ?? rawDate
    }
    
    private static func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private static func fullDateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// 独立的 UIViewRepresentable 来处理所有手势
struct ChartOverlayView: UIViewRepresentable {
    let proxy: ChartProxy
    let plotFrame: CGRect?
    let data: [DayMeasurement]
    @Binding var scrollPosition: Date
    @Binding var visibleDomainLength: TimeInterval
    @Binding var selectedDate: Date?
    let minVisibleDays: Double
    let maxVisibleDays: Double
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // 添加缩放手势
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinchGesture)
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        view.addGestureRecognizer(tapGesture)
        
        // 添加滚动手势
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新 coordinator 的引用
        context.coordinator.proxy = proxy
        context.coordinator.plotFrame = plotFrame
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: ChartOverlayView
        var proxy: ChartProxy
        var plotFrame: CGRect?
        private var initialDomainLength: TimeInterval = 0
        private var initialScrollPosition: Date?
        private var panStartLocation: CGPoint?
        
        init(_ parent: ChartOverlayView) {
            self.parent = parent
            self.proxy = parent.proxy
            super.init()
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .began {
                initialDomainLength = parent.visibleDomainLength
            }
            
            if gesture.state == .changed {
                let minLength = parent.minVisibleDays * 24 * 60 * 60
                let maxLength = parent.maxVisibleDays * 24 * 60 * 60
                let newLength = initialDomainLength / gesture.scale
                DispatchQueue.main.async {
                    self.parent.visibleDomainLength = min(max(newLength, minLength), maxLength)
                }
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view,
                  let plotFrame else { return }
            
            let location = gesture.location(in: view)
            let rawX = location.x - plotFrame.origin.x
            let clampedX = min(max(rawX, 0), proxy.plotSize.width)
            // 关键：必须用 plotArea 的 frame 做坐标换算。缩放后 plotArea 的起点/宽度会变化，
            // 直接用 view.bounds 的相对位置会导致 date 取值偏移。
            guard let date: Date = proxy.value(atX: clampedX) else { return }
  
             let nearest = nearestDate(to: date)
             let normalized = Calendar.current.startOfDay(for: nearest)
  
             DispatchQueue.main.async {
                 if self.parent.selectedDate == nil || !Calendar.current.isDate(self.parent.selectedDate!, inSameDayAs: normalized) {
                     self.parent.selectedDate = normalized
                 }
             }
         }
         
         @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
             guard proxy.plotFrame != nil,
                   let view = gesture.view else { return }
              
              let translation = gesture.translation(in: view)
              
             switch gesture.state {
             case .began:
                 panStartLocation = gesture.location(in: view)
                 initialScrollPosition = parent.scrollPosition
                 
             case .changed:
                 // 计算滚动偏移（水平方向）
                 let deltaX = translation.x
                 
                 // 将像素偏移转换为日期偏移
                 if let startDate = initialScrollPosition,
                    let firstDate = parent.data.first?.date,
                    let lastDate = parent.data.last?.date {
                     
                     // 计算当前可见区域的宽度占比
                     let visibleWidth = view.bounds.width
                     let scrollRatio = deltaX / visibleWidth * 0.5
                     
                     // 计算日期范围
                     let dateRange = lastDate.timeIntervalSince(firstDate)
                     let dateOffset = scrollRatio * dateRange
                     
                     // 计算新的滚动位置
                     let newPosition = startDate.addingTimeInterval(-dateOffset)
                     
                     // 限制滚动范围
                     let clampedPosition = min(max(newPosition, firstDate), lastDate)
                     
                     DispatchQueue.main.async {
                         self.parent.scrollPosition = clampedPosition
                     }
                 }
                 
             case .ended, .cancelled:
                 panStartLocation = nil
                 initialScrollPosition = nil
                 
             default:
                 break
             }
         }
        
        private func nearestDate(to rawDate: Date) -> Date {
            parent.data.min {
                abs($0.date.timeIntervalSince(rawDate)) < abs($1.date.timeIntervalSince(rawDate))
            }?.date ?? rawDate
        }
        
        // 允许所有手势同时进行
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        // 判断手势是否应该开始
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)
                // 只处理水平滑动
                return abs(velocity.x) > abs(velocity.y)
            }
            return true
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisDayView(data: AnalysisDayView.previewMockData)
    }
}

private extension AnalysisDayView {
    static var previewMockData: [DayMeasurement] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let counts = [
            128, 146, 132, 180, 210, 198, 230, 146, 132, 180,
            210, 198, 230, 146, 132, 180, 210, 198, 230, 146,
            132, 180, 210, 198, 230, 146, 132, 180, 210, 198
        ]
        
        return (0..<counts.count).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: -(counts.count - 1) + index, to: today) else { return nil }
            return DayMeasurement(date: date, count: counts[index])
        }
    }
}
