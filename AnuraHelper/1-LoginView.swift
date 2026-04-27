//
//  ContentView.swift
//  AnuraHelper
//
//  Created by Michael Xu on 2026/2/8.
//

import SwiftUI
import Network

struct User: Codable, Sendable {
    let key: String
    let orgName: String
    let email: String
    let password: String
    let region: Region
    var deposits: Double
    var unitPrice: Double
    var billingDate: Date
    var period: DateFilter? = nil
    var customPeriodStartDate: Date? = nil
    var customPeriodEndDate: Date? = nil
    var studyUnitPrices: [String: Double]? = nil
    var token: String? = nil
}

var SharedUsers = [User]()

// User 持久化工具
struct UserStorage {
    static let key = "userList"
    static func save(users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    static func load() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

let kInitialStartDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1)) ?? Date()

// 引入AlertManager
struct LoginView: View {
    @State private var orgName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var multiAccountText: String = ""
    
    @State private var region: Region = .china
    @State private var isMultiAccountMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isMultiAccountMode, forKey: "isMultiAccountMode")
        }
    }
    @State private var isBillingListActive = false
    @StateObject private var alertManager = AlertManager()
    @ObservedObject private var langManager = LanguageManager.shared // 新增，监听语言变化
    @State private var isLoading = false // 新增 loading 状态
    @State private var isFirstCheck = true // 防止多次跳转
    @State private var isNetworkAvailable = true // 新增网络状态
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            NavigationStack {
                ZStack {
                    Color.white.ignoresSafeArea()

                    Group {
                        if isLandscape {
                            ScrollView(.vertical, showsIndicators: false) {
                                loginContent
                                    .frame(maxWidth: 520)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            loginContent
                                .frame(maxWidth: 520)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .alert(isPresented: $alertManager.isPresented) {
                        Alert(
                            title: Text(alertManager.title),
                            message: Text(alertManager.message),
                            dismissButton: .default(Text(alertManager.buttonText)) {
                                alertManager.onDismiss?()
                            }
                        )
                    }
                    // 跳转至BillingListView
                    .navigationDestination(isPresented: $isBillingListActive) {
                        BillingListView().navigationBarHidden(true)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    resignFirstResponder()
                }
                .onAppear {
                    // 启动时自动跳转
                    if isFirstCheck {
                        let users = UserStorage.load()
                        if !users.isEmpty {
                            SharedUsers = users
                            isBillingListActive = true
                        }
                        isFirstCheck = false
                    }
                    // 启动网络监控
                    monitor.pathUpdateHandler = { path in
                        DispatchQueue.main.async {
                            isNetworkAvailable = (path.status == .satisfied)
                        }
                    }
                    monitor.start(queue: monitorQueue)
                }
                .onDisappear {
                    monitor.cancel()
                }
                // 右上角语言切换按钮
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        LanguageSwitchButton()
                    }
                }
            }
        }
        .id(langManager.currentLanguage) // 关键：语言变化时刷新整个视图
        .onAppear {
            isMultiAccountMode = UserDefaults.standard.bool(forKey: "isMultiAccountMode")
        }
    }

    private var loginContent: some View {
        VStack(alignment: .center, spacing: 0) {
            // 标题
            LocalizedText("login_title", font: .system(size: 20, weight: .medium), color: .text)
                .padding(.top, 80)
                .padding(.bottom, 60)
            
            // 输入区域（单账号/多账号切换）
            LoginInputArea(
                isMultiAccountMode: isMultiAccountMode,
                orgName: $orgName,
                email: $email,
                password: $password,
                multiAccountText: $multiAccountText,
                region: $region
            )
                        
            // 切换按钮（右下角）
            HStack {
                Spacer()
                Button(action: {
                    isMultiAccountMode.toggle()
                }) {
                    LocalizedText(isMultiAccountMode ? "login_mode_normal" : "login_mode_multi", font: .system(size: 14, weight: .medium), color: .lightBlue)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 83)

            // 登录按钮
            LoginButton(isLoading: isLoading) {
                UIApplication.shared.resignFirstResponder()
                if !isNetworkAvailable {
                    alertManager.showAlert(title: Localized("alert_title"), message: Localized("network_unavailable"))
                    return
                }
                isLoading = true
                Task {
                    await login()
                }
            }
            
            // 底部说明文字
            BottomNote(text: Localized("login_note"))
                .padding(.top, 20)
                .frame(width: 250)
            
            Spacer(minLength: 90)

            // 底部logo
            LogoImage(image: .companyLogo)
                .padding(.bottom, 10)
            VersionLabel()
                .padding(.bottom, 5)
        }
    }

    func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func login() async {
        if (isMultiAccountMode && multiAccountText.isEmpty) ||
        (!isMultiAccountMode && (orgName.isEmpty || email.isEmpty || password.isEmpty)){
            alertManager.showAlert(title: Localized("alert_title"), message: Localized("alert_fill_all"))
            isLoading = false
            return
        }
        var users = [User]()
        if !isMultiAccountMode {
            let user = User(key: orgName + region.tag,
                            orgName: orgName,
                            email: email,
                            password: password,
                            region: region,
                            deposits: 0,
                            unitPrice: 1.0,
                            billingDate: kInitialStartDate)
            users.append(user)
        } else {
            let strArr = multiAccountText.split(separator: "\n")
            for line in strArr {
                let components = line.split(separator: " ")
                if components.count >= 7 {
                    let org = String(components[0])
                    let email = String(components[1])
                    let password = String(components[2])
                    let deposits = Double(components[3]) ?? 1.0
                    let unitPrice = Double(components[4]) ?? 1.0
                    let billingDate = String(components[5]).dateFromYyyyMMddString ?? kInitialStartDate
                    let region = Region(rawValue: Int(components[6]) ?? 0) ?? .china
                    let user = User(key: org + region.tag,
                                    orgName: org,
                                    email: email,
                                    password: password,
                                    region: region,
                                    deposits: deposits,
                                    unitPrice: unitPrice,
                                    billingDate: billingDate)
                    users.append(user)
                } else {
                    alertManager.showAlert(title: Localized("alert_title"), message: Localized("alert_fill_format"))
                    isLoading = false
                    return
                }
            }
        }
        Task {
            var loginResults = [Result<LoginResponse, Error>]()
            var updatedUsers = [User]()
            await withTaskGroup(of: Result<(User, LoginResponse), Error>.self) { group in
                for user in users {
                    group.addTask {
                        do {
                            let response = try await APIClient.login(email: user.email, password: user.password, org: user.orgName, region: user.region)
                            let updateUser = User(key: user.orgName + "\(user.region.rawValue)",
                                                  orgName: user.orgName,
                                                  email: user.email,
                                                  password: user.password,
                                                  region: user.region,
                                                  deposits: user.deposits,
                                                  unitPrice: user.unitPrice,
                                                  billingDate: user.billingDate,
                                                  token: response.Token)
                            return .success((updateUser, response))
                        } catch {
                            return .failure(error)
                        }
                    }
                }
                for await result in group {
                    switch result {
                    case .success(let (user, _)):
                        updatedUsers.append(user)
                    case .failure(let error):
                        loginResults.append(.failure(error))
                    }
                }
            }
            let failed = loginResults.first(where: { if case .failure(_) = $0 { return true } else { return false } })
            if let fail = failed {
                if case .failure(let error) = fail {
                    alertManager.showAlert(title: Localized("login_failed"), message: error.localizedDescription)
                    isLoading = false
                    return
                }
            }

            // 全部成功，主线程赋值
            await MainActor.run {
                for idx in users.indices {
                    let user = users[idx]
                    if let updateUser = updatedUsers.first(where: { $0.key == user.key }) {
                        SharedUsers.append(updateUser)
                    }
                }
                UserStorage.save(users: updatedUsers)
                isBillingListActive = true
                isLoading = false
            }
        }
    }
}

// 输入区域复用组件
struct LoginInputArea: View {
    var isMultiAccountMode: Bool
    @Binding var orgName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var multiAccountText: String
    @Binding var region: Region // 新增

    var body: some View {
        if isMultiAccountMode {
            VStack(alignment: .leading) {
                LocalizedText("login_multi_input_tip", font: .system(size: 15, weight: .regular), color: .text)
                    .lineLimit(2)
                ZStack(alignment: .topLeading) {
                    ScrollView(.horizontal, showsIndicators: true) {
                        SingleLineTextEditor(text: $multiAccountText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 15)
                            .frame(minWidth: 600, maxWidth: .infinity)
                    }
                    .padding(.trailing, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray, lineWidth: 1 / UIScreen.main.scale)
                    )
                    // 仅当multiAccountText为空时显示示例说明
                    if multiAccountText.isEmpty {
                        let exampleString = Localized("login_multi_example")
                        Text(AttributedString(exampleString))
                            .font(.system(size:10))
                            .foregroundColor(Color(UIColor.systemGray5))
                            .padding(15)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.horizontal, 30)
            .frame(height: 186 + 41)
        } else {
            VStack {
                VStack(alignment: .leading, spacing: 30) {
                    InputField(label: Localized("org_label"), placeholder: "org", text: $orgName)
                    InputField(label: Localized("email_label"), placeholder: "example@gmail.com", text: $email)
                    InputField(label: Localized("password_label"), placeholder: "123456", text: $password, isSecure: true)
                }
                .padding(.horizontal, 30)
                .frame(height: 186)
                
                Picker("", selection: $region) {
                    Text(Region.china.name).tag(Region.china)
                    Text(Region.international.name).tag(Region.international)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                .padding(.top, 2)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// 输入框组件
// 3. 修改 InputField 组件
struct InputField: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State var isPasswordVisible: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.text)
                .frame(width: AutoSize(60, 90), alignment: .trailing)
            Spacer(minLength: 10)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.systemGray5))
                        .padding(10)
                }
                HStack {
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text)
                            .font(.system(size: 14))
                            .foregroundColor(.text)
                            .padding(10)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    } else {
                        TextField("", text: $text)
                            .font(.system(size: 14))
                            .foregroundColor(.text)
                            .padding(10)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                    if isSecure {
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: !isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray, lineWidth: 1 / UIScreen.main.scale)
            )
        }
    }
}

// 登录按钮复用组件
struct LoginButton: View {
    var isLoading: Bool = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .center) {
                LocalizedText(isLoading ? "login_loading" : "login_button", font: .system(size: 13, weight: .medium), color: .white)
                    .frame(maxWidth: .infinity)
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.65)
                            .frame(width: 18, height: 18)
                            .padding(.trailing, 15)
                    }
                }
            }
            .frame(width: 140, height: 40)
            .background(.main)
            .cornerRadius(10)
        }
        .padding(.horizontal, 80)
        .disabled(isLoading)
    }
}

// 底部说明复用组件
struct BottomNote: View {
    var text: String
    var body: some View {
        LocalizedText(text, font: .system(size: 12), color: .main, alignment: .center)
    }
}

struct LogoImage: View {
    var image: ImageResource
    var body: some View {
        Image(image)
            .resizable()
            .frame(width: 120, height: 20)
    }
}

// MARK: - 横向滚动不换行的 TextEditor 封装
struct SingleLineTextEditor: UIViewRepresentable {
    @Binding var text: String
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.textContainerInset = .zero
        textView.font = UIFont.systemFont(ofSize: 12)
        textView.textColor = .text
        textView.delegate = context.coordinator
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.backgroundColor = .clear
        textView.textAlignment = .left
        return textView
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SingleLineTextEditor
        init(_ parent: SingleLineTextEditor) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

// 新增语言切换下拉菜单组件
struct LanguageSwitchButton: View {
    @ObservedObject private var langManager = LanguageManager.shared
    @State private var showSheet = false
    let languages = ["zh-Hans": "中文", "en": "Eglish"]
    var body: some View {
        Button(action: { showSheet = true }) {
            Text(languages[langManager.currentLanguage] ?? "语言")
                .font(.system(size: 12))
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 24) {
                ForEach(languages.keys.sorted(), id: \ .self) { key in
                    Button(action: {
                        langManager.setLanguage(key)
                        showSheet = false
                    }) {
                        Text(languages[key] ?? key)
                            .font(.system(size: 14))
                            .foregroundColor(langManager.currentLanguage == key ? .blue : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                    }
                }
            }
            .padding(10)
        }
    }
}

// 底部版本号组件
struct VersionLabel: View {
    var body: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        Text("v\(version) (\(build))")
            .font(.system(size: 8))
            .foregroundColor(.lightPurple)
    }
}

#Preview {
    LoginView()
}
