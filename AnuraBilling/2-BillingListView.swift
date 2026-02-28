import SwiftUI
import Combine // 修复 ObservableObject 错误

class OrgListModel: ObservableObject {
    @Published var orgs: [OrgInfo] = []
    @Published var billingPeriod = ""
    @Published var billingName = ""
}

struct BillingListView: View {
    let kInitialStartDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1)) ?? Date()
    let kInitialEndDate = Date()
    
    @StateObject private var orgList = OrgListModel()
    @State private var isRefreshing = false
    @State private var refreshCompleted = false // 新增状态
    @State private var totalRequests: Double = 0 // 总请求数
    @State private var completedRequests: Double = 0 // 已完成请求数
    @State private var progressTimer: Timer? = nil // 进度动画定时器
    @Environment(\.presentationMode) private var presentationMode
    @State private var startDateString: String
    @State private var endDateString: String
    @State private var isStartDatePickerPresented = false
    @State private var isEndDatePickerPresented = false
    @State private var startDate: Date
    @State private var endDate: Date
    @StateObject private var alertManager = AlertManager()
    
    init() {
        self.startDateString = kInitialStartDate.yyyyMMddDateString
        self.startDate = kInitialStartDate
        self.endDateString = "至今"
        self.endDate = kInitialEndDate
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部日期选择和按钮
                HStack(alignment: .bottom, spacing: 5) {
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
                    
                    Spacer()
                    
                    NavigationLink(destination: BillingPreviewFullView(orgList: orgList).navigationBarHidden(true)) {
                            Text("账单预览")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .background(orgList.orgs.isEmpty ? Color.gray : Color.deepPurple)
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
                            .background(orgList.orgs.isEmpty ? Color.gray : Color.deepPurple)
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
                        }
                    }) {
                        Image(systemName: "arrow.left.to.line.square")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(20)
                    }
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
            .sheet(isPresented: $isStartDatePickerPresented) {
                VStack {
                    DatePicker("选择开始时间", selection: $startDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, Locale.preferredLanguages.first.map { Locale(identifier: $0) } ?? Locale.current)
                    HStack {
                        Button("重置") {
                            startDate = kInitialStartDate
                            startDateString = startDate.yyyyMMddDateString
                            isStartDatePickerPresented = false
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isRefreshing = true
                            }
                            refreshCompleted = false
                            requestData()
                        }
                        .padding()
                        Spacer()
                        Button("确定") {
                            startDateString = startDate.yyyyMMddDateString
                            isStartDatePickerPresented = false
                            // 日历变更后自动刷新
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isRefreshing = true
                            }
                            refreshCompleted = false
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
                            endDateString = "至今"
                            isEndDatePickerPresented = false
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isRefreshing = true
                            }
                            refreshCompleted = false
                            requestData()
                        }
                        .padding()
                        Spacer()
                        Button("确定") {
                            endDateString = endDate.yyyyMMddDateString
                            isEndDatePickerPresented = false
                            // 日历变更后自动刷新
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isRefreshing = true
                            }
                            refreshCompleted = false
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
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRefreshing = true
                }
                refreshCompleted = false
                requestData()
            }
        }
    }
    
    func requestData() {
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
                totalRequests += Double(studyCount) * 2
                completedRequests = progress * totalRequests
                completedRequests = max(Double(userCount), completedRequests)
                progressTimer?.invalidate()
                progressTimer = nil

                let licences = try await getLicences()
                completedRequests += Double(userCount)
                // 统计 updateStudies 需要的请求数
                var studiesCopy = studies
                try await updateStudies(&studiesCopy, progress: { completedRequests += 1 })
                var orgs = [OrgInfo]()
                for user in SharedUsers {
                    let successCount = totalSuccessMeasurements(for: user, in: studiesCopy)
                    let org = OrgInfo(name: user.orgName,
                                      successCount: successCount,
                                      totalDeposits: user.deposits,
                                      unitPrice: user.unitPrice,
                                      periodSuccess: successCount,
                                      licenses: licences[user.orgName] ?? [],
                                      studies: studiesCopy[user.orgName] ?? [])
                    orgs.append(org)
                }
                if isRefreshing {
                    refreshCompleted = true // 通知刷新完成
                    orgList.orgs = orgs
                    orgList.billingPeriod = "\(startDateString) ~ \(endDateString)"
                    orgList.billingName = "Nuralogix账单" + Date().yyyyMMddhhmmssDateString
                }
            }catch {
                print("getData error: \(error)")
                if isRefreshing {
                    refreshCompleted = true // 即使失败也通知完成
                }
            }
        }
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

    func updateStudies(_ studyDic: inout [String: [StudyResponse]], progress: @escaping () -> Void) async throws {
        let dateStr = startDate.toUTCString()
        let endDateStr = endDate.toUTCString()
        for (orgName, studies) in studyDic {
            var updatedStudies: [StudyResponse] = studies
            await withTaskGroup(of: (Int, Int?).self) { group in
                for (index, study) in studies.enumerated() {
                    group.addTask {
                        do {
                            let info = try await APIClient.getMeasurementInfo(orgName: orgName, studyID: study.ID, date: dateStr, endDate: endDateStr, progress: progress)
                            progress()
                            return (index, info.successCount)
                        } catch {
                            progress()
                            return (index, nil)
                        }
                    }
                }
                for await (index, successCount) in group {
                    if let count = successCount {
                        updatedStudies[index].successMeasurements = count
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
                    .foregroundColor(org.balance < 0 ? .redText : .greenText)
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
                RingSegment(startAngle: .degrees(0), endAngle: .degrees(120))
                    .stroke(Color.deepPurple, lineWidth: 3)
                RingSegment(startAngle: .degrees(120), endAngle: .degrees(240))
                    .stroke(Color.lightBlue, lineWidth: 3)
                RingSegment(startAngle: .degrees(240), endAngle: .degrees(360))
                    .stroke(Color.green, lineWidth: 3)
            }
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(rotation))
            .opacity(0.7)
            // 刷新按钮
            Button(action: {
                if isRefreshing { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRefreshing.toggle()
                }
                refreshCompleted = false // 重置完成状态
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
