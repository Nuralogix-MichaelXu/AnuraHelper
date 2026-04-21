import SwiftUI
import Charts

// 统一的数据模型（折线图使用）
struct DayMeasurement: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct MonthMeasurement: Identifiable {
    let id = UUID()
    /// 用每月第一天作为该月的 x 值
    let monthStart: Date
    /// 该月测量次数（汇总）
    let count: Int
}

struct AnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    /// companyName：StatisticsView 聚合后的公司名（根据 orgName 下划线前缀）
    let companyName: String?

    @State private var isLoading = false
    @State private var completedProgressCalls: Int = 0
    @State private var totalProgressCalls: Int = 0

    @State private var dayData: [DayMeasurement] = []
    @State private var monthData: [MonthMeasurement] = []

    @State private var lastErrorMessage: String? = nil
    @State private var requestTask: Task<Void, Never>? = nil

    init(companyName: String? = nil) {
        self.companyName = companyName
    }

    private var navigationTitleText: String {
        let trimmed = (companyName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Localized("analysis_title_all") : trimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingView(progress: progress)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        AnalysisDayView(data: dayData)
                        AnalysisMonthView(data: monthData)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 10)
                }
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: Binding(get: { lastErrorMessage != nil }, set: { if !$0 { lastErrorMessage = nil } })) {
            Alert(title: Text(Localized("alert_title")), message: Text(lastErrorMessage ?? ""), dismissButton: .default(Text(Localized("confirm"))))
        }
        .onAppear {
            requestData()
        }
        .onDisappear {
            requestTask?.cancel()
        }
    }

    private var progress: Double {
        guard totalProgressCalls > 0 else { return 0 }
        let capped = min(max(completedProgressCalls, 0), totalProgressCalls)
        return Double(capped) / Double(totalProgressCalls)
    }

    private func requestData() {
        requestTask?.cancel()
        lastErrorMessage = nil

        completedProgressCalls = 0

        let users = targetUsers()

        // 进度按“需要请求的 org-时间点”计算（今天/本月强制刷新；其他仅补缓存缺失）
        let dayTimePoints = Self.last30DayStarts()
        let monthTimePoints = Self.last6MonthStarts()
        let missingOrgTimePoints = Self.missingOrgTimePointCount(users: users, dayStarts: dayTimePoints, monthStarts: monthTimePoints)
        totalProgressCalls = max(missingOrgTimePoints, 1) * 2

        isLoading = true

        requestTask = Task(priority: .userInitiated) {
            do {
                async let days = fetchLast30DaysAggregated(users: users)
                async let months = fetchLastSixMonthsAggregated(users: users)

                let (dayResult, monthResult) = try await (days, months)
                try Task.checkCancellation()

                await MainActor.run {
                    self.dayData = dayResult
                    self.monthData = monthResult
                    // 确保进度显示到 100%
                    self.completedProgressCalls = self.totalProgressCalls
                }

                // 延迟一点点再关闭 loading，让 100% 有机会渲染出来
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s

                await MainActor.run {
                    self.isLoading = false
                }
            } catch is CancellationError {
                // 被取消就静默退出
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.lastErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func targetUsers() -> [User] {
        guard let companyName else { return SharedUsers }
        return SharedUsers.filter { Self.companyName(from: $0.orgName) == companyName }
    }

    private func fetchLast30DaysAggregated(users: [User]) async throws -> [DayMeasurement] {
        if users.isEmpty { return [] }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let days = Self.last30DayStarts()

        // 每天聚合：对每个 org 先用缓存（非今天）、缺失则请求并写缓存，再求和
        var results = Array(repeating: 0, count: days.count)

        // 并发：按时间点最多5并发
        let maxConcurrentTimePoints = 5
        var nextIndex = 0

        try await withThrowingTaskGroup(of: (Int, Int).self) { group in
            func addTask(for index: Int) {
                let dayStart = days[index]
                let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart)
                let isToday = calendar.isDate(dayStart, inSameDayAs: todayStart)

                group.addTask {
                    let startStr = Self.isoUTCString(dayStart)
                    let endStr = nextDayStart.map(Self.isoUTCString)

                    var sum = 0

                    // 对每个 org：今天强制刷新；非今天优先缓存
                    for user in users {
                        try Task.checkCancellation()

                        if !isToday, let cached = await Self.cacheGetDay(orgName: user.orgName, region: user.region, dayStart: dayStart) {
                            sum += cached
                            continue
                        }

                        let info = try await APIClient.getMeasurementInfo(
                            orgName: user.orgName,
                            region: user.region,
                            studyID: nil,
                            date: startStr,
                            endDate: endStr,
                            progress: {
                                Task { @MainActor in
                                    self.completedProgressCalls += 1
                                }
                            }
                        )

                        let c = info.successCount
                        await Self.cacheSetDay(orgName: user.orgName, region: user.region, dayStart: dayStart, count: c)
                        sum += c
                    }

                    return (index, sum)
                }
            }

            while nextIndex < min(maxConcurrentTimePoints, days.count) {
                addTask(for: nextIndex)
                nextIndex += 1
            }

            for try await (index, sum) in group {
                results[index] = sum
                try Task.checkCancellation()

                if nextIndex < days.count {
                    addTask(for: nextIndex)
                    nextIndex += 1
                }
            }
        }

        return zip(days, results).map { DayMeasurement(date: $0.0, count: $0.1) }
    }

    private func fetchLastSixMonthsAggregated(users: [User]) async throws -> [MonthMeasurement] {
        if users.isEmpty { return [] }

        let calendar = Calendar.current
        let now = Date()
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let months = Self.last6MonthStarts()

        // 并发：按月份时间点最多5并发
        var results = Array(repeating: 0, count: months.count)
        let maxConcurrent = 5
        var nextIndex = 0

        try await withThrowingTaskGroup(of: (Int, Int).self) { group in
            func addTask(for index: Int) {
                let monthStart = months[index]
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart)
                let isThisMonth = calendar.isDate(monthStart, equalTo: thisMonthStart, toGranularity: .month)

                group.addTask {
                    let startStr = Self.isoUTCString(monthStart)
                    let endStr = nextMonthStart.map(Self.isoUTCString)

                    var sum = 0

                    for user in users {
                        try Task.checkCancellation()

                        if !isThisMonth, let cached = await Self.cacheGetMonth(orgName: user.orgName, region: user.region, monthStart: monthStart) {
                            sum += cached
                            continue
                        }

                        let info = try await APIClient.getMeasurementInfo(
                            orgName: user.orgName,
                            region: user.region,
                            studyID: nil,
                            date: startStr,
                            endDate: endStr,
                            progress: {
                                Task { @MainActor in
                                    self.completedProgressCalls += 1
                                }
                            }
                        )
                        let c = info.successCount
                        await Self.cacheSetMonth(orgName: user.orgName, region: user.region, monthStart: monthStart, count: c)
                        sum += c
                    }

                    return (index, sum)
                }
            }

            while nextIndex < min(maxConcurrent, months.count) {
                addTask(for: nextIndex)
                nextIndex += 1
            }

            for try await (index, sum) in group {
                results[index] = sum
                try Task.checkCancellation()

                if nextIndex < months.count {
                    addTask(for: nextIndex)
                    nextIndex += 1
                }
            }
        }

        return zip(months, results).map { MonthMeasurement(monthStart: $0.0, count: $0.1) }
    }

    // MARK: - Cache + Key (按 orgName+region 存储)

    private struct CachedCount: Codable {
        let count: Int
        let updatedAt: TimeInterval
    }

    private static let cacheDefaults = UserDefaults.standard
    private static let cachePrefix = "analysis.measurementCount"

    private static func dayKey(orgName: String, region: Region, dayStart: Date) -> String {
        "\(cachePrefix).day.\(orgName).\(region.rawValue).\(dayKeyDateString(dayStart))"
    }

    private static func monthKey(orgName: String, region: Region, monthStart: Date) -> String {
        "\(cachePrefix).month.\(orgName).\(region.rawValue).\(monthKeyDateString(monthStart))"
    }

    nonisolated private static func dayKeyDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    nonisolated private static func monthKeyDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private static func cacheGetDay(orgName: String, region: Region, dayStart: Date) -> Int? {
        let key = dayKey(orgName: orgName, region: region, dayStart: dayStart)
        guard let data = cacheDefaults.data(forKey: key),
              let model = try? JSONDecoder().decode(CachedCount.self, from: data) else {
            return nil
        }
        return model.count
    }

    private static func cacheSetDay(orgName: String, region: Region, dayStart: Date, count: Int) {
        let key = dayKey(orgName: orgName, region: region, dayStart: dayStart)
        let model = CachedCount(count: count, updatedAt: Date().timeIntervalSince1970)
        if let data = try? JSONEncoder().encode(model) {
            cacheDefaults.set(data, forKey: key)
        }
    }

    private static func cacheGetMonth(orgName: String, region: Region, monthStart: Date) -> Int? {
        let key = monthKey(orgName: orgName, region: region, monthStart: monthStart)
        guard let data = cacheDefaults.data(forKey: key),
              let model = try? JSONDecoder().decode(CachedCount.self, from: data) else {
            return nil
        }
        return model.count
    }

    private static func cacheSetMonth(orgName: String, region: Region, monthStart: Date, count: Int) {
        let key = monthKey(orgName: orgName, region: region, monthStart: monthStart)
        let model = CachedCount(count: count, updatedAt: Date().timeIntervalSince1970)
        if let data = try? JSONEncoder().encode(model) {
            cacheDefaults.set(data, forKey: key)
        }
    }

    private static func missingOrgTimePointCount(users: [User], dayStarts: [Date], monthStarts: [Date]) -> Int {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()

        var count = 0

        // Day: today always fetch; others only if org cache missing
        for day in dayStarts {
            let isToday = calendar.isDate(day, inSameDayAs: todayStart)
            for user in users {
                if isToday {
                    count += 1
                } else if cacheGetDay(orgName: user.orgName, region: user.region, dayStart: day) == nil {
                    count += 1
                }
            }
        }

        // Month: this month always fetch; others only if org cache missing
        for month in monthStarts {
            let isThisMonth = calendar.isDate(month, equalTo: thisMonthStart, toGranularity: .month)
            for user in users {
                if isThisMonth {
                    count += 1
                } else if cacheGetMonth(orgName: user.orgName, region: user.region, monthStart: month) == nil {
                    count += 1
                }
            }
        }

        return count
    }

    /// 单个时间点：对该公司下所有 org 进行聚合（同一个日期/月份区间）
    private func fetchOnePoint(users: [User], dateStr: String?, endDateStr: String?) async throws -> Int {
        // 限制并发数，避免请求过多导致限流
        let maxConcurrent = 5

        var nextIndex = 0
        var total = 0

        try await withThrowingTaskGroup(of: Int.self) { group in
            while nextIndex < min(maxConcurrent, users.count) {
                let user = users[nextIndex]
                group.addTask {
                    let info = try await APIClient.getMeasurementInfo(
                        orgName: user.orgName,
                        region: user.region,
                        studyID: nil,
                        date: dateStr,
                        endDate: endDateStr,
                        progress: {
                            Task { @MainActor in
                                self.completedProgressCalls += 1
                            }
                        }
                    )
                    return info.successCount
                }
                nextIndex += 1
            }

            for try await count in group {
                total += count
                try Task.checkCancellation()

                if nextIndex < users.count {
                    let user = users[nextIndex]
                    group.addTask {
                        let info = try await APIClient.getMeasurementInfo(
                            orgName: user.orgName,
                            region: user.region,
                            studyID: nil,
                            date: dateStr,
                            endDate: endDateStr,
                            progress: {
                                Task { @MainActor in
                                    self.completedProgressCalls += 1
                                }
                            }
                        )
                        return info.successCount
                    }
                    nextIndex += 1
                }
            }
        }

        return total
    }

    private static func last30DayStarts(now: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<30).compactMap { offset in
            calendar.date(byAdding: .day, value: -(29 - offset), to: today)
        }
    }

    private static func last6MonthStarts(now: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return (0..<6).compactMap { i in
            calendar.date(byAdding: .month, value: -5 + i, to: thisMonthStart)
        }
    }

    nonisolated private static func isoUTCString(_ date: Date) -> String {
        // 与 Common.swift 的 Date.toUTCString 默认格式保持一致
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.string(from: date)
    }

    private static func companyName(from orgName: String) -> String {
        let parts = orgName.split(separator: "_", maxSplits: 1, omittingEmptySubsequences: false)
        let prefix = parts.first.map(String.init) ?? orgName
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? orgName : trimmed
    }
}

private struct LoadingView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
            }
            .frame(width: 120, height: 120)

            Text(Localized("analysis_loading"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(Localized("analysis_loading_tip"))
                .font(.system(size: 15))
                .foregroundStyle(.blue)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        // 预览模式下通常没有 SharedUsers/token，UI 仍可预览（数据为空）。
        AnalysisView(companyName: "lssd")
    }
}
