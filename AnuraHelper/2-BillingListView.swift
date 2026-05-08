import SwiftUI
import Combine

class OrgListModel: ObservableObject {
    @Published var orgs: [OrgInfo] = []
    @Published var billingPeriod = ""
    @Published var billingName = ""
    @Published var updateTime = Date()
    @Published var isUpdateFail = false
    @Published var isPeriodNone = true
}

enum DateFilter: String, CaseIterable, Codable {
    case none = "none"
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
        case .none: return Localized("datefilter_none")
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
    @Environment(\.dismiss) private var dismiss
    @StateObject private var alertManager = AlertManager()
    @StateObject private var orgList = OrgListModel()
    @State private var isRefreshing = false
    @State private var refreshCompleted = false // 新增状态
    @State private var totalRequests: Double = 0 // 总请求数
    @State private var completedRequests: Double = 0 // 已完成请求数
    @State private var progressTimer: Timer? = nil // 进度动画定时器
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
    @State private var selectedFilter: DateFilter = .none
    @State private var lastSelectedFilter: DateFilter = .none
    @State private var isCustomDatePickerPresented = false
    @State private var isMenuOpen = false
    @State private var isExpanded = false
    @State private var currentTask: Task<Void, Never>? = nil // 新增: 当前请求任务

    // iPad 横屏分栏：当前选中的 org index
    @State private var selectedOrgIndex: Int? = nil

    private var isSplitMode: Bool {
        UIDevice.current.isIPad && UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let useSplitOnIPadLandscape = UIDevice.current.isIPad && isLandscape

            Group {
                if useSplitOnIPadLandscape {
                    NavigationStack {
                        splitLayout
                    }
                } else {
                    NavigationStack {
                        singleColumnLayout
                    }
                }
            }
            // Put modifiersLayer once at the top level so it always renders above content
            .overlay(modifiersLayer)
        }
    }

    // MARK: - iPad 横屏分栏布局

    private var splitLayout: some View {
        HStack(spacing: 0) {
            // 左侧：列表
            VStack(spacing: 0) {
                header
                footer
            }
            .frame(width: 420)
            .background(Color.white)

            Divider().background(Color(UIColor.systemGray5))

            // 右侧：详情
            ZStack {
                Color.white
                if let index = selectedOrgIndex, orgList.orgs.indices.contains(index) {
                    BillingDetailView(org: $orgList.orgs[index], period: orgList.billingPeriod)
                        .navigationBarHidden(false)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.6))
                        Text(Localized("select_org_to_view_detail"))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear {
            if selectedOrgIndex == nil, !orgList.orgs.isEmpty {
                selectedOrgIndex = 0
            }
            if #unavailable(iOS 26) {
                setNavigationBarAppearance()
            }
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
                    selectedFilter = .none
                }
                performFilter(selectedFilter)
            }
        }
    }

    // MARK: - 单栏（iPhone / iPad竖屏）布局（保持原有）

    private var singleColumnLayout: some View {
        VStack(spacing: 0) {
            header
            footer
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear {
            if #unavailable(iOS 26) {
                setNavigationBarAppearance()
            }
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
                    selectedFilter = .none
                }
                performFilter(selectedFilter)
            }
        }
    }

    // MARK: - 复用子视图

    private var header: some View {
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
                                lastSelectedFilter = .none
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
                
                NavigationLink(destination: StatisticsView(orgList: orgList)) {
                        LocalizedText("statistics_billing_title", font: .system(size: 9), color: .white)
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
                        if isSplitMode {
                            Button {
                                selectedOrgIndex = index
                            } label: {
                                BillingOrgCard(org: org)
                                    .disabled(true)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(selectedOrgIndex == index ? Color.deepPurple : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            NavigationLink(destination: BillingDetailView(org: $orgList.orgs[index], period: orgList.billingPeriod)) {
                                EmptyView()
                            }
                            .opacity(0)
                            .buttonStyle(PlainButtonStyle())

                            BillingOrgCard(org: org)
                                .disabled(true)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: index == 0 ? 20 : 0, leading: 20, bottom: 10, trailing: 20))
                }
            }
            .listStyle(.plain)
            .padding(.horizontal, isSplitMode ? 0 : (UIDevice.current.isIPad ? 150 : 0))
            .onChange(of: orgList.orgs.count) { _, newCount in
                // 分栏模式下刷新数据时，保持选中有效，必要时默认选中第一个
                guard isSplitMode else { return }
                if newCount == 0 {
                    selectedOrgIndex = nil
                } else if let idx = selectedOrgIndex, idx >= newCount {
                    selectedOrgIndex = 0
                } else if selectedOrgIndex == nil {
                    selectedOrgIndex = 0
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 分栏进入时若没有选中且有数据，则默认选中第一个
            if selectedOrgIndex == nil, !orgList.orgs.isEmpty {
                selectedOrgIndex = 0
            }
        }
    }

    private var footer: some View {
        // 底部刷新按钮和返回按钮
        HStack {
            Button(action: {
                alertManager.showAlert(title: Localized("alert_title"), message: Localized("alert_logout_confirm")) {
                    currentTask?.cancel()
                    SharedUsers.removeAll()
                    UserStorage.clear()
                    dismiss()
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

    @ViewBuilder
    private var modifiersLayer: some View {
        // Important: this layer is always overlaid on top of the page.
        // It must be transparent AND not intercept touches unless we actually need it.
        let shouldInterceptTouches = isMenuOpen || isStartDatePickerPresented || isEndDatePickerPresented || alertManager.isPresented

        Color.clear
            .contentShape(Rectangle())
            .allowsHitTesting(shouldInterceptTouches)
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
                            .frame(height: isExpanded ? Double(40 * DateFilter.allCases.count) : 0, alignment: .top)
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
                            startDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: startDate) ?? Date()
                            isStartDatePickerPresented = false
                            // 日历变更后自动刷新
                            requestData()
                        }
                        .padding()
                    }
                    .padding(.horizontal, 50)
                }
                // iPad 上 .medium 经常会裁切 graphical 日历，改为 large
                .presentationDetents(UIDevice.current.isIPad ? [.large] : [.medium])
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
                .presentationDetents(UIDevice.current.isIPad ? [.large] : [.medium])
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
                totalRequests += Double(studyCount) * (selectedFilter == .none ? 0 : 2)
                var studiesCopy3 = [String: [StudyResponse]]()
                var billingDateDic = [String: Date]()
                for key in studies.keys {
                    let orgStudies = studies[key] ?? []
                    guard let user = SharedUsers.first(where: { $0.key == key }) else {
                        continue
                    }
                    studiesCopy3[key] = orgStudies
                    billingDateDic[key] = user.billingDate
                }
                if !studiesCopy3.isEmpty {
                    totalRequests += Double(studiesCopy3.values.flatMap { $0 }.count) * 2
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
                    totalRequests += Double(studiesCopy4.values.flatMap { $0 }.count) * 2
                }

                completedRequests = progress * totalRequests
                var factor = (1 - progress)
                if orgList.orgs.count == 0 {
                    factor *= totalRequests / (totalRequests - Double(userCount)) * 1.02
                }
                
                var studiesCopy = studies
                if selectedFilter != .none {
                    try await APIClient.updateStudies(&studiesCopy, nil, startDate, endDate, progress: { completedRequests += 1 * factor })
                }
                
                for (key, studies2) in studiesCopy {
                    guard var studies1 = studiesCopy[key] else { continue }
                    for study2 in studies2 {
                        if let idx = studies1.firstIndex(where: { $0.ID == study2.ID }) {
                            studies1[idx].periodSuccessMeasurements = study2.totalSuccessMeasurements
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
                    orgList.isPeriodNone = selectedFilter == .none
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
            case .none:
                startDate = now
                endDate = now
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
    
    func periodSuccessMeasurements(for user: User, in studies: [String: [StudyResponse]]) -> Int? {
        if selectedFilter == .none { return nil }
        guard let studyArray = studies[user.key] else { return 0 }
        return studyArray.compactMap { $0.periodSuccessMeasurements ?? $0.totalSuccessMeasurements }.reduce(0, +)
    }
}

extension BillingListView {
    func setNavigationBarAppearance() {
        // 仅控制返回箭头样式与位置，不隐藏返回文字
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        // 返回按钮文字隐藏
        let back = UIBarButtonItemAppearance()
        back.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        back.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        back.disabled.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = back

        let base = UIImage(systemName: "chevron.backward")
        let shifted = base?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 10))
        let grayShifted = shifted?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(grayShifted, transitionMaskImage: grayShifted)

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
    }
}

#Preview {
    BillingListView()
}
