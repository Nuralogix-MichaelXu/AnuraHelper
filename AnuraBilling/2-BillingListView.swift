import SwiftUI
import Combine // 修复 ObservableObject 错误

class OrgListModel: ObservableObject {
    @Published var orgs: [OrgInfo] = []
}

struct BillingListView: View {
    @StateObject private var orgList = OrgListModel()
    @State private var isRefreshing = false
    @State private var refreshCompleted = false // 新增状态
    @Environment(\.presentationMode) private var presentationMode
    @State private var startDate: String = "2020.12.25"
    @State private var endDate: String = "至今"
    @State private var isStartDatePickerPresented = false
    @State private var isEndDatePickerPresented = false
    @State private var startDateValue: Date = Calendar.current.date(from: DateComponents(year: 2020, month: 12, day: 25)) ?? Date()
    @State private var endDateValue: Date = Date()
    @StateObject private var alertManager = AlertManager()
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale.current // 跟随系统语言
        return formatter
    }
    
    func formattedDate(_ date: Date) -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let selected = Calendar.current.startOfDay(for: date)
        if selected == today {
            return "至今"
        } else {
            return dateFormatter.string(from: date)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部日期选择和按钮
                HStack(alignment: .bottom, spacing: 5) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 0) {
                            Image(systemName: "calendar")
                                .resizable()
                                .frame(width: 11, height: 11)
                                .foregroundColor(Color.text)
                            Text("开始时间")
                                .font(.system(size: 11))
                                .foregroundColor(.text)
                                .padding(.leading, 5)
                        }
                        Text(startDate)
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
                        HStack(spacing: 0) {
                            Image(systemName: "calendar")
                                .resizable()
                                .frame(width: 11, height: 11)
                                .foregroundColor(Color.text)
                            Text("截止时间")
                                .font(.system(size: 11))
                                .foregroundColor(.text)
                                .padding(.leading, 5)
                        }
                        Text(endDate)
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
                    
                    NavigationLink(destination: BillingPreviewFullView().navigationBarHidden(true)) {
                        Text("账单预览")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(.deepPurple)
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: BillingPreviewView().navigationBarHidden(true)) {
                        Text("发送账单")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(.deepPurple)
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 25)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                Divider()
                    .background(Color(UIColor.systemGray5))
                
                // 卡片列表
                List {
                    ForEach(Array(orgList.orgs.enumerated()), id: \.element.id) { index, org in
                        ZStack(alignment: .top) {
                            NavigationLink(destination: BillingDetailView(org: $orgList.orgs[index])) {
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
                    DatePicker("选择开始时间", selection: $startDateValue, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, Locale.preferredLanguages.first.map { Locale(identifier: $0) } ?? Locale.current)
                    Button("确定") {
                        startDate = dateFormatter.string(from: startDateValue)
                        isStartDatePickerPresented = false
                    }
                    .padding()
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $isEndDatePickerPresented) {
                VStack {
                    DatePicker("选择截止时间", selection: $endDateValue, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, Locale.preferredLanguages.first.map { Locale(identifier: $0) } ?? Locale.current)
                    Button("确定") {
                        endDate = formattedDate(endDateValue)
                        isEndDatePickerPresented = false
                    }
                    .padding()
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
                isRefreshing = true
                refreshCompleted = false
                requestData()
            }
        }
    }
    
    func requestData() {
        Task {
            do {
                let licences = try await getLicences()
                var studies = try await getStudies()
                try await updateStudies(&studies)
                var orgs = [OrgInfo]()
                for user in SharedUsers {
                    let successCount = totalSuccessMeasurements(for: user, in: studies)
                    let org = OrgInfo(name: user.orgName,
                                      successCount: successCount,
                                      totalDeposits: user.deposits,
                                      unitPrice: user.unitPrice,
                                      periodSuccess: successCount,
                                      licenses: licences[user.orgName] ?? [],
                                      studies: studies[user.orgName] ?? [])
                    orgs.append(org)
                }
                orgList.orgs = orgs
                if isRefreshing {
                    refreshCompleted = true // 通知刷新完成
                }
            }catch {
                print("getData error: \(error)")
                if isRefreshing {
                    refreshCompleted = true // 即使失败也通知完成
                }
            }
        }
    }
}

extension BillingListView {
    func updateStudies(_ studyDic: inout [String: [StudyResponse]]) async throws {
        for (orgName, studies) in studyDic {
            // 新数组用于收集更新后的 StudyResponse
            var updatedStudies: [StudyResponse] = studies
            await withTaskGroup(of: (Int, Int?).self) { group in
                for (index, study) in studies.enumerated() {
                    let studyID = study.ID
                    group.addTask {
                        do {
                            let info = try await APIClient.getMeasurementInfo(orgName: orgName, studyID: studyID)
                            return (index, info.successCount)
                        } catch {
                            return (index, nil) // 失败时不更新
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
    
    // 通过user的orgName查找studies字典中对应的StudyResponse数组，并计算所有StudyResponse的successMeasurements之和
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
                isRefreshing.toggle()
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
                isRefreshing = false
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
