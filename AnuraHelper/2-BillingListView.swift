import SwiftUI
import Combine

class OrgListModel: ObservableObject {
    @Published var orgs: [OrgInfo] = []
    @Published var billingPeriod = ""
    @Published var billingName = ""
    @Published var updateTime = Date()
    @Published var isUpdateFail = false
}

enum DateFilter: String, CaseIterable, Codable {
    case all = "all"
    case today = "today"
    case yesterday = "yesterday"
    case beforeYesterday = "beforeYesterday"
    case thisWeek = "thisWeek"
    case lastWeek = "lastWeek"
    case thisMonth = "thisMonth"
    case lastMonth = "lastMonth"
    case halfYear = "halfYear"
    case oneYear = "oneYear"
    case custom = "custom"
    
    var localized: String {
        switch self {
        case .all: return Localized("datefilter_all")
        case .today: return Localized("datefilter_today")
        case .yesterday: return Localized("datefilter_yesterday")
        case .beforeYesterday: return Localized("datefilter_beforeYesterday")
        case .thisWeek: return Localized("datefilter_thisWeek")
        case .lastWeek: return Localized("datefilter_lastWeek")
        case .thisMonth: return Localized("datefilter_thisMonth")
        case .lastMonth: return Localized("datefilter_lastMonth")
        case .halfYear: return Localized("datefilter_halfYear")
        case .oneYear: return Localized("datefilter_oneYear")
        case .custom: return Localized("datefilter_custom")
        }
    }
    
    var shortString: String {
        if LanguageManager.shared.isCNLanguage() { return self.localized }
        switch self {
        case .beforeYesterday:
            return "DBY"
        case .halfYear:
            return "LHY"
        default:
            return self.localized
        }
    }
    
    var endDateIsNow: Bool {
        if self == .all ||
            self == .today ||
            self == .thisWeek ||
            self == .thisMonth ||
            self == .halfYear ||
            self == .oneYear {
            return true
        }
        return false
    }
}

struct BillingListView: View {
    @StateObject private var alertManager = AlertManager()
    @StateObject private var orgList = OrgListModel()
    @State private var isRefreshing = false
    @State private var refreshCompleted = false // 新增状态
    @State private var totalRequests: Double = 0 // 总请求数
    @State private var completedRequests: Double = 0 // 已完成请求数
    @State private var progressTimer: Timer? = nil // 进度动画定时器
    @Environment(\.presentationMode) private var presentationMode
    @State private var startDateString: String = ""
    @State private var endDateString: String = ""
    @State private var isStartDatePickerPresented = false
    @State private var isEndDatePickerPresented = false
    @State private var savedUpdateTime = Date()
    @State private var startDate = Date() {
        didSet {
            savedStartDate = startDate
        }
    }
    @State private var endDate  = Date()
    {
       didSet {
           savedEndDate = endDate
       }
    }
    @State private var savedStartDate: Date?  {
        didSet {
            if let savedStartDate = savedStartDate {
                startDateString = savedStartDate.yyyyMMddDateString
            } else {
                startDateString = kInitialStartDate.yyyyMMddDateString
            }
            for idx in SharedUsers.indices {
                SharedUsers[idx].customPeriodStartDate = savedStartDate
            }
            UserStorage.save(users: SharedUsers)
        }
    }
    @State private var savedEndDate: Date? {
        didSet {
            if let savedEndDate = savedEndDate {
                endDateString = savedEndDate.yyyyMMddDateString
            } else {
                endDateString = Localized("until_now")
            }
            
            var shouldSavedEndDate = savedEndDate
            let calendar = Calendar.current
            if calendar.isDate(shouldSavedEndDate ?? Date(), inSameDayAs: Date()) {
                shouldSavedEndDate = nil
            }
            for idx in SharedUsers.indices {
                SharedUsers[idx].customPeriodEndDate = shouldSavedEndDate
            }
            UserStorage.save(users: SharedUsers)
        }
    }
    @State private var selectedFilter: DateFilter = .all {
        didSet {
            for idx in SharedUsers.indices {
                SharedUsers[idx].period = selectedFilter
            }
            UserStorage.save(users: SharedUsers)
        }
    }
    @State private var lastSelectedFilter: DateFilter = .all
    @State private var isCustomDatePickerPresented = false
    @State private var isMenuOpen = false
    @State private var isExpanded = false
    @State private var currentTask: Task<Void, Never>? = nil // 新增: 当前请求任务
    
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
                                    LocalizedText("start_time", font: .system(size: 11), color: .text)
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
                                    LocalizedText("end_time", font: .system(size: 11), color: .text)
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
                                if lastSelectedFilter == .custom {
                                    lastSelectedFilter = .all
                                }
                                selectedFilter = lastSelectedFilter
                                performFilter(lastSelectedFilter, savedUpdateTime != orgList.updateTime ? true : false)
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
                                LocalizedText("period_select", font: .system(size: 12), color: .text.opacity(0.75))
                                    .padding(.trailing, 5)

                                // 自定义下拉菜单按钮
                                Button(action: {
                                    isMenuOpen.toggle()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                        isExpanded = true
                                    }
                                }) {
                                    HStack {
                                        Text(selectedFilter.shortString)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.lightBlue)
                                            .lineLimit(1)
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
                    
                    NavigationLink(destination: BillingPreviewFullView(orgList: orgList)) {
                            LocalizedText("bill_preview", font: .system(size: 9), color: .white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .background(Color.deepPurple)
                                .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(orgList.orgs.isEmpty)

                    NavigationLink(destination: BillingSendingView(orgList: orgList)) {
                        LocalizedText("send_bill", font: .system(size: 9), color: .white)
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
                        let progress = totalRequests == 0 ? 0 : Int(min(max(completedRequests, 0), totalRequests) / totalRequests * 100)
                        Text("\(progress)%")
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
                        alertManager.showAlert(title: Localized("alert_title"), message: Localized("alert_logout_confirm")) {
                            currentTask?.cancel()
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
                    let title = orgList.isUpdateFail ? Localized("last_update_fail") : Localized("last_update_time")
                    let text = isRefreshing ? Localized("refreshing") : title + orgList.updateTime.yyyyMMddhhmmssDateString2
                    Text(text)
                        .font(.system(size: 11))
                        .foregroundColor(orgList.isUpdateFail && refreshCompleted ? .red : .main)
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
                                        
                                        if filter == .custom {
                                            savedUpdateTime = orgList.updateTime
                                        }
                                        
                                        performFilter(filter, filter != .custom ? true : false)
                                    }) {
                                        HStack {
                                            Text(filter.localized)
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
                                        .frame(width: AutoSize(100, 190))
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
                            .frame(width: AutoSize(100, 190), alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: isExpanded ? 440 : 0, alignment: .top)
                            .clipped()
                            .animation(.easeInOut(duration: 0.15), value: isExpanded)
                        
                            Spacer()
                        }
                        .padding(.leading, AutoSize(80, 65))
                        .padding(.top, 60)
                    }
                }
            )

            .sheet(isPresented: $isStartDatePickerPresented) {
                VStack {
                    DatePicker(Localized("select_start_time"), selection: $startDate, in: ...endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale.preferredLanguages.first.map { Locale(identifier: $0) } ?? Locale.current)
                    HStack {
                        Button(Localized("reset")) {
                            startDate = kInitialStartDate
                            savedStartDate = nil
                            isStartDatePickerPresented = false
                            requestData()
                        }
                        .padding()
                        Spacer()
                        Button(Localized("confirm")) {
                            startDate = startDate
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
                    DatePicker(Localized("select_end_time"), selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale.preferredLanguages.first.map { Locale(identifier: $0) } ?? Locale.current)
                    HStack {
                        Button(Localized("reset")) {
                            endDate = Date()
                            savedEndDate = nil
                            isEndDatePickerPresented = false
                            requestData()
                        }
                        .padding()
                        Spacer()
                        Button(Localized("confirm")) {
                            let fixedEndDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? Date()
                            endDate = min(fixedEndDate, Date())
                            if fixedEndDate > Date() {
                                savedEndDate = nil
                            }
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
                    secondaryButton: .cancel(Text(Localized("cancel"))) {
                        alertManager.isPresented = false
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if orgList.orgs.isEmpty && !isRefreshing {
                if let period = SharedUsers.first?.period {
                    selectedFilter = period
                    if period == .custom {
                        isCustomDatePickerPresented = true
                        if let start = SharedUsers.first?.customPeriodStartDate {
                            startDate = start
                            savedStartDate = startDate
                        } else {
                            startDate = kInitialStartDate
                            savedStartDate = startDate
                        }
                        if let end = SharedUsers.first?.customPeriodEndDate {
                            endDate = end
                            savedEndDate = endDate
                        } else {
                            endDate = Date()
                            savedEndDate = nil
                        }
                    }
                } else {
                    selectedFilter = .all
                }
                
                performFilter(selectedFilter)
            }
        }
    }
    
    func requestData() {
        currentTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            isRefreshing = true
        }
        refreshCompleted = false

        totalRequests = 0
        completedRequests = 0
        currentTask = Task {
            do {
                let userCount = SharedUsers.count
                var studies = [String: [StudyResponse]]()
                if orgList.orgs.count > 0 {
                    for org in orgList.orgs {
                        studies[org.key] = org.studies
                    }
                } else {
                    totalRequests = Double(userCount) // getLicences + getStudies
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

                    studies = try await APIClient.getStudies()
                    progressTimer?.invalidate()
                    progressTimer = nil
                }
                
                for key in studies.keys {
                    var orgStudies = studies[key] ?? []
                    if let user = SharedUsers.first(where: { $0.key == key }) {
                        for idx in orgStudies.indices {
                            if let unitPrice = user.studyUnitPrices?[orgStudies[idx].ID] {
                                orgStudies[idx].unitPrice = unitPrice
                            } else {
                                orgStudies[idx].unitPrice = user.unitPrice
                            }
                        }
                    }
                    studies[key] = orgStudies
                }
                let studyCount = studies.values.flatMap { $0 }.count
                let progress = totalRequests == 0 ? 0 : completedRequests / totalRequests
                totalRequests += Double(studyCount) * (selectedFilter == .all ? 3 : 6)
                var studiesCopy3 = [String: [StudyResponse]]()
                var billingDateDic = [String: Date]()
                for key in studies.keys {
                    let orgStudies = studies[key] ?? []
                    guard let user = SharedUsers.first(where: { $0.key == key }) else {
                        continue
                    }
                    if user.billingDate != kInitialStartDate {
                        studiesCopy3[key] = orgStudies
                        billingDateDic[key] = user.billingDate
                    }
                }
                if !studiesCopy3.isEmpty {
                    totalRequests += Double(studiesCopy3.values.flatMap { $0 }.count) * 3
                }
                
                var studiesCopy4 = [String: [StudyResponse]]()
                for key in studies.keys {
                    var orgStudies = studies[key] ?? []
                    guard let user = SharedUsers.first(where: { $0.key == key }) else {
                        continue
                    }
                    for idx in orgStudies.indices {
                        orgStudies[idx].reset()
                    }

                    if user.billingDate > startDate && user.billingDate < endDate {
                        if lastSelectedFilter.endDateIsNow {
                            for idx in orgStudies.indices {
                                orgStudies[idx].isPerioContainBilling = true
                            }
                            studies[key] = orgStudies
                        } else {
                            studiesCopy4[key] = orgStudies
                        }
                    } else {
                        for idx in orgStudies.indices {
                            if user.billingDate > endDate {
                                orgStudies[idx].periodBillingSuccessMeasurements = 0
                            } else {
                                orgStudies[idx].periodBillingSuccessMeasurements = nil
                            }
                        }
                        studies[key] = orgStudies
                    }
                }
                
                if !studiesCopy4.isEmpty {
                    totalRequests += Double(studiesCopy4.values.flatMap { $0 }.count) * 3
                }

                completedRequests = progress * totalRequests
                var factor = (1 - progress)
                if orgList.orgs.count == 0 {
                    factor *= totalRequests / (totalRequests - Double(userCount)) * 1.02
                }
                
                var studiesCopy = studies
                try await APIClient.updateStudies(&studiesCopy, nil, nil, nil, progress: { completedRequests += 1 * factor })
                var studiesCopy2 = studiesCopy
                if selectedFilter != .all {
                    try await APIClient.updateStudies(&studiesCopy2, nil, startDate, endDate, progress: { completedRequests += 1 * factor })
                }
                
                for (key, studies2) in studiesCopy2 {
                    guard var studies1 = studiesCopy[key] else { continue }
                    for study2 in studies2 {
                        if let idx = studies1.firstIndex(where: { $0.ID == study2.ID }) {
                            if selectedFilter != .all {
                                studies1[idx].periodSuccessMeasurements = study2.totalSuccessMeasurements
                            } else {
                                studies1[idx].periodSuccessMeasurements = studies1[idx].totalSuccessMeasurements
                            }
                        }
                    }
                    studiesCopy[key] = studies1
                }
                
                if !studiesCopy3.isEmpty {
                    try await APIClient.updateStudies(&studiesCopy3, billingDateDic, nil, nil, progress: { completedRequests += 1 * factor })
                    for (key, studies3) in studiesCopy3 {
                        guard var studies1 = studiesCopy[key] else { continue }
                        for study3 in studies3 {
                            if let idx = studies1.firstIndex(where: { $0.ID == study3.ID }) {
                                studies1[idx].billingSuccessMeasurements = study3.totalSuccessMeasurements
                            }
                        }
                        studiesCopy[key] = studies1
                    }
                }
                
                if !studiesCopy4.isEmpty {
                    try await APIClient.updateStudies(&studiesCopy4, billingDateDic, nil, endDate, progress: { completedRequests += 1 * factor })
                    for (key, studies4) in studiesCopy4 {
                        guard var studies1 = studiesCopy[key] else { continue }
                        for study4 in studies4 {
                            if let idx = studies1.firstIndex(where: { $0.ID == study4.ID }) {
                                studies1[idx].periodBillingSuccessMeasurements = study4.totalSuccessMeasurements
                            }
                        }
                        studiesCopy[key] = studies1
                    }
                }
                
                var orgs = [OrgInfo]()
                for user in SharedUsers {
                    let totalSuccessCount = totalSuccessMeasurements(for: user, in: studiesCopy)
                    let periodSuccessCount = periodSuccessMeasurements(for: user, in: studiesCopy)
                    let org = OrgInfo(key: user.orgName + user.region.tag,
                                      region: user.region,
                                      name: user.orgName,
                                      successCount: totalSuccessCount,
                                      totalDeposits: user.deposits,
                                      unitPrice: user.unitPrice,
                                      periodSuccess: periodSuccessCount,
                                      billingDate: user.billingDate,
                                      startDate: startDate,
                                      endDate: endDate,
                                      studies: studiesCopy[user.key] ?? [])
                    orgs.append(org)
                }
                if isRefreshing {
                    refreshCompleted = true // 通知刷新完成
                    orgList.orgs = orgs
                    if selectedFilter == .custom {
                        orgList.billingPeriod = "\(startDateString) ~ \(endDateString)"
                    } else {
                        orgList.billingPeriod = selectedFilter.localized
                    }
                    orgList.updateTime = Date()
                    orgList.billingName = Localized("bill_prefix") + orgList.updateTime.yyyyMMddhhmmssDateString
                }
                orgList.isUpdateFail = false
            } catch {
                if isRefreshing {
                    refreshCompleted = true // 即使失败也通知完成
                }
                orgList.updateTime = Date()
                orgList.isUpdateFail = true
                if SharedUsers.count != 0 {
                    print("getData error: \(error.localizedDescription)")
                    alertManager.showAlert(title: Localized("alert_title"), message: Localized("Error: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    func performFilter(_ filter: DateFilter, _ needRequest: Bool = true) {
        // 计算时间区间
        let now = Date()
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 强制一周从周一开始，其他国家可能是从周日开始

        if filter == .custom {
            if lastSelectedFilter.endDateIsNow {
                savedEndDate = nil
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                isCustomDatePickerPresented = true
            }
        } else {
            switch filter {
            case .all:
                startDate = kInitialStartDate
                endDate = now
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
                startDate = weekStart
                endDate = now
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
        }
        if needRequest {
            lastSelectedFilter = filter
            requestData()
        }
    }
}

extension BillingListView {
    func totalSuccessMeasurements(for user: User, in studies: [String: [StudyResponse]]) -> Int {
        guard let studyArray = studies[user.key] else { return 0 }
        return studyArray.compactMap { $0.totalSuccessMeasurements }.reduce(0, +)
    }
    
    func periodSuccessMeasurements(for user: User, in studies: [String: [StudyResponse]]) -> Int {
        guard let studyArray = studies[user.key] else { return 0 }
        return studyArray.compactMap { $0.periodSuccessMeasurements ?? $0.totalSuccessMeasurements }.reduce(0, +)
    }
}

#Preview {
    BillingListView()
}
