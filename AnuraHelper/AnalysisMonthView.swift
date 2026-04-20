import SwiftUI
import Charts

struct AnalysisMonthView: View {
    let data: [MonthMeasurement]

    /// Charts 的选中值（会在交互过程中抖动/变 nil），因此我们做一层稳定化
    @State private var selectedMonth: Date?
    @State private var lastStableSelectedMonth: Date?

    /// 给右侧留一点空白，让最右侧柱子视觉上更靠左
    private var xDomain: ClosedRange<Date>? {
        guard let minDate = data.min(by: { $0.monthStart < $1.monthStart })?.monthStart,
              let maxDate = data.max(by: { $0.monthStart < $1.monthStart })?.monthStart else {
            return nil
        }

        // 右侧 padding：可按需要调整（例如 10~20 天）
        let rightPad = Calendar.current.date(byAdding: .day, value: 15, to: maxDate) ?? maxDate
        return minDate...rightPad
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localized("analysis_month_title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value(Localized("analysis_axis_month"), item.monthStart),
                        y: .value(Localized("analysis_axis_measurement_count"), item.count),
                        width: .fixed(22)
                    )
                    .foregroundStyle(isSelected(item.monthStart) ? Color.orange : Color.blue)
                    .cornerRadius(0)
                }

                if let selected = selectedDataPoint {
                    RuleMark(x: .value(Localized("analysis_selected_month"), selected.monthStart))
                        .foregroundStyle(.gray.opacity(0.35))
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                }
            }
            .frame(height: 260)
            .chartXScale(domain: xDomain ?? (Date.distantPast...Date.distantFuture))
            // 关键修复：plotArea 的 leading padding 会导致最左侧一部分点击区域落在 plotArea 外
            // 这里给 plotArea 本身增加 padding，而不是把 plotArea 整体右移
            .chartPlotStyle { plotArea in
                plotArea
                    .padding(.leading, 10)
            }
            // 关键：用 overlay 自己处理命中，不依赖 chartXSelection
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    guard let plotFrameAnchor = proxy.plotFrame else { return }
                                    let plotFrame = geo[plotFrameAnchor]

                                    // 把触点 clamp 到 plotArea 范围内（解决最左/最右边点击落在 plotArea 外无响应）
                                    let rawX = gesture.location.x - plotFrame.origin.x
                                    let clampedX = min(max(rawX, 0), proxy.plotSize.width)

                                    guard let date: Date = proxy.value(atX: clampedX) else { return }
                                    let snapped = nearestMonth(to: date)
                                    let normalized = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: snapped)) ?? snapped
                                    selectedMonth = normalized
                                }
                        )
                }
            }
            .chartXAxis {
                AxisMarks(values: data.map { $0.monthStart }) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(Self.monthLabel(for: date))
                                .padding(.leading, -4)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }

            if let selected = selectedDataPoint {
                Text(String(format: Localized("analysis_selected_month_format"), Self.yearMonthLabel(for: selected.monthStart), formatCount(selected.count)))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Text(Localized("analysis_month_hint"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedMonth else { return false }
        return Calendar.current.isDate(date, equalTo: selectedMonth, toGranularity: .month)
    }

    private var selectedDataPoint: MonthMeasurement? {
        guard let selectedMonth else { return nil }
        let nearest = nearestMonth(to: selectedMonth)
        return data.first { Calendar.current.isDate($0.monthStart, equalTo: nearest, toGranularity: .month) }
    }

    private func nearestMonth(to rawDate: Date) -> Date {
        data.min {
            abs($0.monthStart.timeIntervalSince(rawDate)) < abs($1.monthStart.timeIntervalSince(rawDate))
        }?.monthStart ?? rawDate
    }

    private static func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return String(format: Localized("analysis_month_label_format"), formatter.string(from: date))
    }

    private static func yearMonthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        AnalysisMonthView(data: AnalysisMonthView.previewMockData)
    }
}

private extension AnalysisMonthView {
    static var previewMockData: [MonthMeasurement] {
        let calendar = Calendar.current
        let now = Date()
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let months: [MonthMeasurement] = (0..<6).compactMap { i in
            let offset = -6 + i
            guard let monthStart = calendar.date(byAdding: .month, value: offset, to: thisMonthStart) else { return nil }

            let base = 120
            let trend = i * 12
            let noise = Int.random(in: -15...18)
            let count = max(0, base + trend + noise)
            return MonthMeasurement(monthStart: monthStart, count: count)
        }

        return months
    }
}
