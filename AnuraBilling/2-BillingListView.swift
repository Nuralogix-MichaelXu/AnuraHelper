import SwiftUI
import Combine // 修复 ObservableObject 错误

class OrgListModel: ObservableObject {
    @Published var orgs: [OrgInfo] = []
    @Published var billingPeriod = ""
    @Published var billingName = ""
    @Published var updateTime = Date()
}

enum DateFilter: String, CaseIterable {
    case all = "全部"
    case today = "今天"
    case yesterday = "昨天"
    case beforeYesterday = "前天"
    case thisWeek = "本周"
    case lastWeek = "上周"
    case thisMonth = "本月"
    case lastMonth = "上月"
    case halfYear = "近半年"
    case oneYear = "近一年"
    case custom = "自定义"
}

struct BillingListView: View {
    let kInitialStartDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1)) ?? Date()
    
    @StateObject private var orgList = OrgListModel()
    @State private var isRefreshing = false
    @State private var refreshCompleted = false // 新增状态
    @State private var totalRequests: Double = 0 // 总请求数
    {
        didSet {
            print("\(completedRequests)" + "/" + "\(totalRequests)")
        }
    }
    @State private var completedRequests: Double = 0 // 已完成请求数
    {
        didSet {
            print("\(completedRequests)" + "/" + "\(totalRequests)")
        }
    }
    @State private var progressTimer: Timer? = nil // 进度动画定时器
    @Environment(\.presentationMode) private var presentationMode
    @State private var startDateString: String = ""
    @State private var endDateString: String = ""
    @State private var isStartDatePickerPresented = false
    @State private var isEndDatePickerPresented = false
    @State private var startDate = Date() {
        didSet {
            startDateString = startDate.yyyyMMddDateString
        }
    }
    @State private var endDate  = Date() {
        didSet {
            endDateString = endDate.yyyyMMddDateString
        }
    }
    @State private var savedStartDate: Date?
    @State private var savedEndDate: Date?
    @StateObject private var alertManager = AlertManager()
    @State private var selectedFilter: DateFilter = .all
    @State private var lastSelectedFilter: DateFilter = .all
    @State private var isCustomDatePickerPresented = false
    @State private var isMenuOpen = false
    @State private var isExpanded = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部日期选择和按钮
                HStack(alignment: .bottom, spacing: 5) {
                    if isCustomDatePickerPresented {
                        HStack(alignment: .bottom, spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .resizable()
                                        .frame(width: 11, height: 11)
                                        .foregroundColor(Color.text)
                                    Text("开始时间")
                                        .font(.system(size: 11))
                                        .foregroundColor(.text)
                                        .frame(width: 60, alignment: .leading)
                                }

                                Text(startDateString)
                                    .font(.system(size: 11))
                                    .frame(width: 80)
                                    .foregroundColor(.lightBlue)
                                    .padding(.vertical, 6)
                                    .background(.lightPurple)
                                    .cornerRadius(5)
                                    .onTapGesture {
                                        isStartDatePickerPresented = true
                                    }
                            }
                            Text("~")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .padding(.bottom, 3)
                                .frame(width: 25)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .resizable()
                                        .frame(width: 11, height: 11)
                                        .foregroundColor(Color.text)
                                    Text("截止时间")
                                        .font(.system(size: 11))
                                        .foregroundColor(.text)
                                        .frame(width: 60, alignment: .leading)
                                }

                                Text(endDateString)
                                    .font(.system(size: 11))
                                    .frame(width: 80)
                                    .foregroundColor(.lightBlue)
                                    .padding(.vertical, 6)
                                    .background(.lightPurple)
                                    .cornerRadius(5)
                                    .onTapGesture {
                                        isEndDatePickerPresented = true
                                    }
                            }
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isCustomDatePickerPresented = false
                                }
                                selectedFilter = .all
                                requestData()
                            }) {
                                Image(systemName: "arrowshape.turn.up.backward.fill")
                                    .resizable()
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.lightPurple)
                                    .padding(6)
                            }
                        }

                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("周期选择:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.text.opacity(0.75))
                                    .padding(.trailing, 5)

                                // 自定义下拉菜单按钮
                                Button(action: {
                                    isMenuOpen.toggle()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                        isExpanded = true
                                    }
                                }) {
                                    HStack {
                                        Text(selectedFilter.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.lightBlue)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(.lightBlue)
                                            .rotationEffect(.degrees(isMenuOpen ? 180 : 0))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.lightPurple)
                                    .cornerRadius(5)
                                }
                                
                                Spacer()
                            }
                            .zIndex(1)
                            
                        }
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: BillingPreviewFullView(orgList: orgList).navigationBarHidden(true)) {
                            Text("账单预览")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .background(Color.deepPurple)
                                .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(orgList.orgs.isEmpty)

                    NavigationLink(destination: BillingSendingView(orgList: orgList).navigationBarHidden(true)) {
                        Text("发送账单")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color.deepPurple)
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(orgList.orgs.isEmpty)
                }
                .padding(.top, 25)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                Divider()
                    .background(Color(UIColor.systemGray5))
                // 刷新进度条
                // 在进度条区域外层加动画和过渡
                if isRefreshing && totalRequests > 0 {
                    HStack {
                        ProgressView(value: min(max(completedRequests, 0), totalRequests), total: totalRequests)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(height: 8)
                        Text("\(Int(min(max(completedRequests, 0), totalRequests) / totalRequests * 100))%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                            .frame(alignment: .trailing)
                    }
                    .padding(.trailing, 5)
                    .onDisappear {
                        completedRequests = 0
                        progressTimer?.invalidate()
                        progressTimer = nil
                    }
                }

                // 卡片列表
                List {
                    ForEach(Array(orgList.orgs.enumerated()), id: \.element.id) { index, org in
                        ZStack(alignment: .top) {
                            NavigationLink(destination: BillingDetailView(org: $orgList.orgs[index], period: orgList.billingPeriod)) {
                                EmptyView()
                            }
                            .opacity(0)
                            .buttonStyle(PlainButtonStyle())
                            
                            BillingOrgCard(org: org)
                                .disabled(true)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: index == 0 ? 20 : 0, leading: 20, bottom: 10, trailing: 20))
                    }
                }
                .listStyle(.plain)
                
                // 底部刷新按钮和返回按钮
                HStack {
                    Button(action: {
                        alertManager.showAlert(title: "提示", message: "确定要退出登录吗?") {
                            presentationMode.wrappedValue.dismiss()
                            SharedUsers.removeAll()
                            UserStorage.clear()
                        }
                    }) {
                        Image(systemName: "arrow.left.to.line.square")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(20)
                    }
                    Spacer()
                    let text = isRefreshing ? "数据更新中，请稍后..." : "上次更新时间: \(orgList.updateTime.yyyyMMddhhmmssDateString2)"
                    Text(text)
                        .font(.system(size: 11))
                        .foregroundColor(.main)
                    Spacer()
                    RefreshButton(isRefreshing: $isRefreshing, refreshCompleted: $refreshCompleted, requestData: requestData)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.lightPurple.opacity(0.8), Color.white]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .background(Color.white)
            .overlay(
                Group {
                    if isMenuOpen {
                        // 半透明遮罩
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                            .onTapGesture {
                                isExpanded = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    isMenuOpen = false
                                }
                            }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            // 菜单列表
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(DateFilter.allCases.enumerated()), id: \.element) { index, filter in
                                    Button(action: {
                                        selectedFilter = filter
                                        isExpanded = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                            isMenuOpen = false
                                        }
                                        
                                        performFilter(filter)
                                    }) {
                                        HStack {
                                            Text(filter.rawValue)
                                                .font(.system(size: 12))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if filter == selectedFilter {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .frame(minWidth: 100)
                                        .background(
                                            filter == selectedFilter ?
                                            Color.blue.opacity(0.1) :
                                                Color.white
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if index < DateFilter.allCases.count - 1 {
                                        Divider()
                                            .padding(.leading, 10)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .frame(width: 120, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: isExpanded ? 440 : 0, alignment: .top)
                            .clipped()
                            .animation(.easeInOut(duration: 0.15), value: isExpanded)
                        
                            Spacer()
                        }
                        .padding(.leading, 90)
                        .padding(.top, 60)
                    }
                }
            )

            .sheet(isPresented: $isStartDatePickerPresented) {
                VStack {
                    DatePicker("选择开始时间", selection: $startDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, Locale.preferredLanguages.first.map { Locale(identifier: $0) } ?? Locale.current)
                    HStack {
                        Button("重置") {
                            startDate = kInitialStartDate
                            savedStartDate = nil
                            isStartDatePickerPresented = false
                            requestData()
                        }
                        .padding()
                        Spacer()
                        Button("确定") {
                            savedStartDate = startDate
                            startDateString = startDate.yyyyMMddDateString
                            isStartDatePickerPresented = false
                            // 日历变更后自动刷新
                            requestData()
                        }
                        .padding()
                    }
                    .padding(.horizontal, 50)
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $isEndDatePickerPresented) {
                VStack {
                    DatePicker("选择截止时间", selection: $endDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, Locale.preferredLanguages.first.map { Locale(identifier: $0) } ?? Locale.current)
                    HStack {
                        Button("重置") {
                            endDate = Date()
                            savedEndDate = nil
                            endDateString = "至今"
                            isEndDatePickerPresented = false
                            requestData()
                        }
                        .padding()
                        Spacer()
                        Button("确定") {
                            savedEndDate = endDate
                            endDateString = endDate.yyyyMMddDateString
                            isEndDatePickerPresented = false
                            // 日历变更后自动刷新
                            requestData()
                        }
                        .padding()
                    }
                    .padding(.horizontal, 50)
                }
                .presentationDetents([.medium])
            }
            .alert(isPresented: $alertManager.isPresented) {
                Alert(
                    title: Text(alertManager.title),
                    message: Text(alertManager.message),
                    primaryButton: .default(Text(alertManager.buttonText)) {
                        alertManager.onDismiss?()
                    },
                    secondaryButton: .cancel(Text("取消")) {
                        alertManager.isPresented = false
                    }
                )
            }
        }
        .onAppear {
            if orgList.orgs.isEmpty && !isRefreshing {
                requestData()
            }
        }
    }
    
    func requestData() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isRefreshing = true
        }
        refreshCompleted = false

        totalRequests = 0
        completedRequests = 0
        let userCount = SharedUsers.count
        totalRequests = Double(userCount) * 2 // getLicences + getStudies

        // 启动动画定时器
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                completedRequests += 0.002 * totalRequests
                if completedRequests >= totalRequests * 0.9 {
                    progressTimer?.invalidate()
                    progressTimer = nil
                }
            }
        }

        Task {
            do {
                let studies = try await getStudies()
                let studyCount = studies.values.flatMap { $0 }.count
                let progress = completedRequests / totalRequests
                totalRequests += Double(studyCount) * (selectedFilter == .all ? 3 : 6)
                completedRequests = progress * totalRequests
                completedRequests = max(Double(userCount), completedRequests)
                progressTimer?.invalidate()
                progressTimer = nil

                let licences = try await getLicences()
                completedRequests += Double(userCount)
                // 统计 updateStudies 需要的请求数
                var studiesCopy = studies
                try await updateStudies(&studiesCopy, progress: { completedRequests += 1 })
                var studiesCopy2 = studies
                if selectedFilter == .all {
                    studiesCopy2 = studiesCopy
                } else {
                    try await updateStudies(&studiesCopy2, startDate, endDate, progress: { completedRequests += 1 })
                }

                var orgs = [OrgInfo]()
                for user in SharedUsers {
                    let successCount = totalSuccessMeasurements(for: user, in: studiesCopy)
                    let successCount2 = totalSuccessMeasurements(for: user, in: studiesCopy2)
                    let org = OrgInfo(name: user.orgName,
                                      successCount: successCount,
                                      totalDeposits: user.deposits,
                                      unitPrice: user.unitPrice,
                                      periodSuccess: successCount2,
                                      licenses: licences[user.orgName] ?? [],
                                      studies: studiesCopy[user.orgName] ?? [],
                                      periodStudies: studiesCopy2[user.orgName] ?? [])
                    orgs.append(org)
                }
                if isRefreshing {
                    refreshCompleted = true // 通知刷新完成
                    orgList.orgs = orgs
                    if selectedFilter == .custom {
                        orgList.billingPeriod = "\(startDateString) ~ \(endDateString)"
                    } else {
                        orgList.billingPeriod = selectedFilter.rawValue
                    }
                    orgList.updateTime = Date()
                    orgList.billingName = "NuraLogix账单" + orgList.updateTime.yyyyMMddhhmmssDateString
                }
            }catch {
                print("getData error: \(error)")
                if isRefreshing {
                    refreshCompleted = true // 即使失败也通知完成
                }
            }
        }
    }
    
    func performFilter(_ filter: DateFilter) {
        if filter == .custom {
            if lastSelectedFilter == .all {
                startDate = kInitialStartDate
                endDateString = "至今"
            } else if lastSelectedFilter == .today {
                endDateString = "至今"
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                isCustomDatePickerPresented = true
            }
        } else {
            // 计算时间区间
            let now = Date()
            var calendar = Calendar.current
            calendar.firstWeekday = 2 // 强制一周从周一开始，其他国家可能是从周日开始
            switch filter {
            case .all:
                startDateString = ""
                endDateString = ""
                startDate = Date()
                endDate = Date()
            case .today:
                let start = calendar.startOfDay(for: now)
                startDate = start
                endDate = now
            case .yesterday:
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
                let start = calendar.startOfDay(for: yesterday)
                let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? yesterday
                startDate = start
                endDate = end
            case .beforeYesterday:
                let beforeYesterday = calendar.date(byAdding: .day, value: -2, to: now) ?? now
                let start = calendar.startOfDay(for: beforeYesterday)
                let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: beforeYesterday) ?? beforeYesterday
                startDate = start
                endDate = end
            case .thisWeek:
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? now
                let endOfWeek = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEnd) ?? weekEnd
                startDate = weekStart
                endDate = endOfWeek
            case .lastWeek:
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
                let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
                let lastWeekEnd = calendar.date(byAdding: .day, value: -1, to: weekStart) ?? weekStart
                let endOfLastWeek = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastWeekEnd) ?? lastWeekEnd
                startDate = lastWeekStart
                endDate = endOfLastWeek
            case .thisMonth:
                let comps = calendar.dateComponents([.year, .month], from: now)
                let monthStart = calendar.date(from: comps) ?? now
                startDate = monthStart
                endDate = now
            case .lastMonth:
                let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                let lastMonthComps = calendar.dateComponents([.year, .month], from: lastMonthDate)
                let lastMonthStart = calendar.date(from: lastMonthComps) ?? lastMonthDate
                let range = calendar.range(of: .day, in: .month, for: lastMonthStart)
                let lastDay = range?.count ?? 30
                let lastMonthEnd = calendar.date(bySetting: .day, value: lastDay, of: lastMonthStart) ?? lastMonthStart
                let endOfLastMonth = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastMonthEnd) ?? lastMonthEnd
                startDate = lastMonthStart
                endDate = endOfLastMonth
            case .halfYear:
                let halfYearAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
                startDate = halfYearAgo
                endDate = now
            case .oneYear:
                let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
                startDate = oneYearAgo
                endDate = now
            default:
                break
            }
            requestData()
        }
        lastSelectedFilter = filter
    }

    // 修改 getLicences、getStudies、updateStudies 支持进度回调
    func getLicences() async throws -> [String: [LicenseResponse]] {
        var licensesDic = [String: [LicenseResponse]]()
        var errors = [Error]()
        await withTaskGroup(of: Result<(String, [LicenseResponse]), Error>.self) { group in
            for user in SharedUsers {
                group.addTask {
                    do {
                        let licenses = try await APIClient.getLicences(orgName: user.orgName, limit: 3)
                        return .success((user.orgName, licenses))
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case .success(let (orgName, licenses)):
                    licensesDic[orgName] = licenses
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        if !errors.isEmpty {
            throw errors.first!
        }
        return licensesDic
    }

    func getStudies() async throws -> [String: [StudyResponse]] {
        var studiesDic = [String: [StudyResponse]]()
        var errors = [Error]()
        await withTaskGroup(of: Result<(String, [StudyResponse]), Error>.self) { group in
            for user in SharedUsers {
                group.addTask {
                    do {
                        let studies = try await APIClient.getStudies(orgName: user.orgName, limit: 5)
                        return .success((user.orgName, studies))
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case .success(let (orgName, studies)):
                    studiesDic[orgName] = studies
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        if !errors.isEmpty {
            throw errors.first!
        }
        return studiesDic
    }

    func updateStudies(_ studyDic: inout [String: [StudyResponse]], _ startDate: Date? = nil, _ endDate: Date? = nil, progress: @escaping () -> Void) async throws {
        var dateStr: String? = nil
        var endDateStr: String? = nil
        if let startDate = startDate { dateStr = startDate.toUTCString() }
        if let endDate = endDate { endDateStr = endDate.toUTCString() }
        
        for (orgName, studies) in studyDic {
            var updatedStudies: [StudyResponse] = studies
            await withTaskGroup(of: (Int, Int?, Int?).self) { group in
                for (index, study) in studies.enumerated() {
                    group.addTask {
                        do {
                            let info = try await APIClient.getMeasurementInfo(orgName: orgName, studyID: study.ID, date: dateStr, endDate: endDateStr, progress: progress)
                            return (index, info.successCount, info.failCount)
                        } catch {
                            progress()
                            return (index, nil, nil)
                        }
                    }
                }
                for await (index, successCount, failCount) in group {
                    if let count = successCount {
                        updatedStudies[index].successMeasurements = count
                    }
                    if let count = failCount {
                        updatedStudies[index].failCount = count
                    }
                }
            }
            studyDic[orgName] = updatedStudies
        }
    }
}

extension BillingListView {
    func totalSuccessMeasurements(for user: User, in studies: [String: [StudyResponse]]) -> Int {
        guard let studyArray = studies[user.orgName] else { return 0 }
        return studyArray.compactMap { $0.successMeasurements }.reduce(0, +)
    }
}

struct BillingOrgCard: View {
    let org: OrgInfo
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("组织名称: ")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.text)
                Text(org.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.text)
            }
            .padding(.bottom, 15)
            
            let bottomMargin: CGFloat = 10
            
            HStack(spacing: 0) {
                Text("许可证(个): \(org.licenseCount)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                
                Spacer()
                Text("研究(个): \(org.studyCount)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                
                Spacer()
                Text("测量成功(次): \(org.successCount)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
            }
            .padding(.bottom, bottomMargin)
            
            HStack(spacing: 0) {
                Text("总充值(元): \(org.totalDepositsString)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                Spacer()
                Text("单价(元/次): \(org.unitPriceString)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
            }
            .padding(.bottom, bottomMargin)
            
            
            HStack(spacing: 0) {
                Text("总消费(元): \(org.totalCostString)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                Spacer()
                Text("余额(元): ")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                Text("\(org.balanceString)")
                    .font(.system(size: 11))
                    .foregroundColor(org.balanceColor)
            }
            .padding(.bottom, bottomMargin)
            
            HStack(spacing: 0) {
                Text("周期内测量成功(次): \(org.periodSuccess)")
                    .font(.system(size: 11))
                    .foregroundColor(.lightBlue)
                Spacer()
                Text("周期内消费(元): \(org.periodCostString)")
                    .font(.system(size: 11))
                    .foregroundColor(.lightBlue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 15)
        .background(.lightPurple)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 5, y: 5)
    }
}

#Preview {
    BillingListView()
}

// MARK: - 刷新按钮带三色分段旋转动画
struct RefreshButton: View {
    @Binding var isRefreshing: Bool
    @Binding var refreshCompleted: Bool
    var requestData: () -> Void
    @State private var rotation: Double = 0
    @State private var timer: Timer? = nil
    
    func startRotationAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            rotation += 6
            if rotation >= 360 { rotation -= 360 }
        }
    }
    
    var body: some View {
        ZStack() {
            // 三色分段圆环
            ZStack {
                RingSegment(startAngle: .degrees(0), endAngle: .degrees(110))
                    .stroke(Color.deepPurple, lineWidth: 3)
                RingSegment(startAngle: .degrees(120), endAngle: .degrees(230))
                    .stroke(Color.deepPurple, lineWidth: 3)
                RingSegment(startAngle: .degrees(240), endAngle: .degrees(350))
                    .stroke(Color.deepPurple, lineWidth: 3)
            }
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(rotation))
            .opacity(0.7)
            // 刷新按钮
            Button(action: {
                if isRefreshing { return }
                startRotationAnimation()
                requestData()
            }) {
                Text(isRefreshing ? "加载中" : "刷新")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 35, height: 35)
                    .background(.deepPurple)
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.6), radius: 5, x: 5, y: 5)
            }
        }
        .padding(.trailing, 20)
        .onChange(of: isRefreshing) { refreshing in
            if refreshing {
                startRotationAnimation()
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
        .onChange(of: refreshCompleted) { completed in
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

// MARK: - 圆环分段 Shape
struct RingSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle - .degrees(90),
                    endAngle: endAngle - .degrees(90),
                    clockwise: false)
        return path
    }
}
