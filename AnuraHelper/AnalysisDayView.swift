import SwiftUI
import Charts

struct AnalysisDayView: View {
    let data: [DayMeasurement]

    /// Charts 的原始选中值（可能抖动/变 nil）
    @State private var rawSelectedDate: Date?
    /// 稳定选中值（UI 展示只依赖它）
    @State private var selectedDate: Date?

    // 默认显示30天，可横向滚动查看更多
    @State private var visibleDomainLength: TimeInterval = 7 * 24 * 60 * 60
    @State private var scrollPosition: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30日测量趋势")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("测量次数", item.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    .lineStyle(.init(lineWidth: 2))

                    PointMark(
                        x: .value("日期", item.date),
                        y: .value("测量次数", item.count)
                    )
                    .foregroundStyle(.blue)
                }

                if let selected = selectedDataPoint {
                    RuleMark(x: .value("选中日期", selected.date))
                        .foregroundStyle(.gray.opacity(0.35))
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))

                    PointMark(
                        x: .value("选中日期", selected.date),
                        y: .value("选中测量次数", selected.count)
                    )
                    .symbolSize(80)
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 260)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: visibleDomainLength)
            .chartScrollPosition(x: $scrollPosition)
            .chartXSelection(value: $rawSelectedDate)
            // 只从 rawSelectedDate 推导稳定值，避免回写同一状态导致“一帧多次更新”
            .onChange(of: rawSelectedDate) { _, newValue in
                guard let newValue else { return } // 不处理 nil，保留上一次稳定值
                let snapped = nearestDate(to: newValue)
                let normalized = Calendar.current.startOfDay(for: snapped)

                if let selectedDate {
                    if !Calendar.current.isDate(selectedDate, inSameDayAs: normalized) {
                        self.selectedDate = normalized
                    }
                } else {
                    self.selectedDate = normalized
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
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

            if let selected = selectedDataPoint {
                Text("已选中：\(Self.fullDateLabel(for: selected.date))，测量次数：\(selected.count)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Text("可左右滑动查看更多日期，点击折线图查看当天测量次数")
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
