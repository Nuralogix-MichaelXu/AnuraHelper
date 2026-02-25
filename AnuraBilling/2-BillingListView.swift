import SwiftUI

struct BillingListView: View {
    // 示例数据
    let orgs: [OrgInfo] = (1...10).map { i in
        OrgInfo(
            name: "Org\(i)",
            licenseCount: i % 3 + 1,
            studyCount: i % 4 + 1,
            successCount: 10000 * i,
            totalDeposits: 10000 * (11 - i),
            unitPrice: Double(0.8 + 0.1 * Double(i % 5)),
            totalCost: 9000 * i,
            balance: 10000 * (11 - i) - 9000 * i,
            periodSuccess: 1000 * i,
            periodCost: Double(800 * i)
        )
    }
    
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
                    ForEach(Array(orgs.enumerated()), id: \.element.id) { index, org in
                        ZStack(alignment: .top) {
                            NavigationLink(destination: BillingDetailView(org: org)) {
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
                    RefreshButton()
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
                Text("总充值(元): \(org.totalDeposits)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                Spacer()
                Text("单价(元/次): \(String(format: "%.1f", org.unitPrice))")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
            }
            .padding(.bottom, bottomMargin)
            
            
            HStack(spacing: 0) {
                Text("总消费(元): \(org.totalCost)")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                Spacer()
                Text("余额(元): ")
                    .font(.system(size: 11))
                    .foregroundColor(.text)
                Text("\(org.balance)")
                    .font(.system(size: 11))
                    .foregroundColor(org.balance < 0 ? .redText : .greenText)
            }
            .padding(.bottom, bottomMargin)
            
            HStack(spacing: 0) {
                Text("周期内测量成功(次): \(org.periodSuccess)")
                    .font(.system(size: 11))
                    .foregroundColor(.lightBlue)
                Spacer()
                Text("周期内消费(元): \(String(format: "%.1f", org.periodCost))")
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
    @State private var isRefreshing = false
    @State private var rotation: Double = 0
    @State private var timer: Timer? = nil
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
                isRefreshing.toggle()
                if isRefreshing {
                    // 启动定时器
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
                        rotation += 6
                        if rotation >= 360 { rotation -= 360 }
                    }
                } else {
                    // 停止定时器
                    timer?.invalidate()
                    timer = nil
                }
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
        .onDisappear {
            timer?.invalidate()
            timer = nil
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
