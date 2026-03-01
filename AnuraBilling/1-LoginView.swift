//
//  ContentView.swift
//  AnuraBilling
//
//  Created by Michael Xu on 2026/2/8.
//

import SwiftUI

struct User: Sendable {
    let orgName: String
    let email: String
    let password: String
    let deposits: Double
    let unitPrice: Double
    var token: String? = nil
}

var SharedUsers = [User]()

// 引入AlertManager
struct LoginView: View {
    @State private var orgName: String = "support"
    @State private var email: String = "michaelxu@nuralogix.ai"
    @State private var password: String = "Xq1988050414132024!"
    @State private var isMultiAccountMode: Bool = false
    @State private var multiAccountText: String = """
        support michaelxu@nuralogix.ai Xq1988050414132024! 200000 0.8
        support michaelxu@nuralogix.ai Xq1988050414132024! 5000 1.2
        support michaelxu@nuralogix.ai Xq1988050414132024! 5000 1.2
        """
    @State private var isBillingListActive = false
    @StateObject private var alertManager = AlertManager()
    @State private var isLoading = false // 新增 loading 状态
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                VStack(alignment: .center, spacing: 0) {
                    // 标题
                    Text("请登录")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.text)
                        .padding(.top, 80)
                        .padding(.bottom, 60)
                    
                    // 输入区域（单账号/多账号切换）
                    LoginInputArea(
                        isMultiAccountMode: isMultiAccountMode,
                        orgName: $orgName,
                        email: $email,
                        password: $password,
                        multiAccountText: $multiAccountText
                    )
                                
                    // 切换按钮（右下角）
                    HStack {
                        Spacer()
                        Button(action: {
                            isMultiAccountMode.toggle()
                        }) {
                            Text(isMultiAccountMode ? "普通登录" : "多账号登录")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.lightBlue)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                    .padding(.bottom, 83)

                    // 登录按钮
                    LoginButton(isLoading: isLoading) {
                        UIApplication.shared.resignFirstResponder()
                        isLoading = true
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
//                            isBillingListActive = true
//                            isLoading = false
//                        }
                        Task {
                            await login()
                        }
                    }
                    
                    // 底部说明文字
                    BottomNote(text: "· 请使用NuraLogix提供的管理员账号登录 ·")
                        .padding(.top, 20)
                    
                    Spacer()

                    // 底部logo
                    LogoImage(image: .companyLogo)
                        .padding(.bottom, 10)
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
        }
    }
    
    func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func login() async {
        if (isMultiAccountMode && multiAccountText.isEmpty) ||
        (!isMultiAccountMode && (orgName.isEmpty || email.isEmpty || password.isEmpty)){
            alertManager.showAlert(title: "提示", message: "请填写完整信息")
            isLoading = false
            return
        }
        var users = [User]()
        if !isMultiAccountMode {
            let user = User(orgName: orgName,
                            email: email,
                            password: password,
                            deposits: 999999,
                            unitPrice: 1.0)
            users.append(user)
        } else {
            let strArr = multiAccountText.split(separator: "\n")
            for line in strArr {
                let components = line.split(separator: " ")
                if components.count >= 5 {
                    let org = String(components[0])
                    let email = String(components[1])
                    let password = String(components[2])
                    let deposits = Double(components[3]) ?? 1.0
                    let unitPrice = Double(components[4]) ?? 1.0
                    let user = User(orgName: org,
                                    email: email,
                                    password: password,
                                    deposits: deposits,
                                    unitPrice: unitPrice)
                    users.append(user)
                }
            }
        }
        Task {
            var loginResults = [Result<LoginResponse, Error>]()
            var updatedUsers = [User]()
            var tag: Int = 0 // Test code
            await withTaskGroup(of: Result<(User, LoginResponse), Error>.self) { group in
                for user in users {
                    group.addTask {
                        do {
                            let response = try await APIClient.login(email: user.email, password: user.password, org: user.orgName)
                            tag += 1
                            let updateUser = User(orgName: user.orgName + "\(tag)",
                                                  email: user.email,
                                                  password: user.password,
                                                  deposits: user.deposits,
                                                  unitPrice: user.unitPrice,
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
                    alertManager.showAlert(title: "登录失败", message: error.localizedDescription)
                    isLoading = false
                    return
                }
            }
            // 全部成功，主线程赋值
            await MainActor.run {
                SharedUsers = updatedUsers
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
    
    var body: some View {
        if isMultiAccountMode {
            VStack(alignment: .leading) {
                Text("请按标准格式输入账号相关信息：")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.text)
                    .frame(height: 20)
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
                        let exampleString = "格式如下，多账号请换行区分：\n组织名称 账号 密码 已充值金额 单价\n\n例如：\norg1 example1@gmail.com 123456 500000 0.8\norg2 example2@gmail.com 123456 200000 1.0\norg3 example3@gmail.com 123456 100000 1.2"
                        Text(AttributedString(exampleString))
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.systemGray5))
                            .padding(15)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.horizontal, 30)
            .frame(height: 186)
        } else {
            VStack() {
                InputField(label: "组织名称", placeholder: "org", text: $orgName)
                Spacer()
                InputField(label: "电子邮箱", placeholder: "example@gmail.com", text: $email)
                Spacer()
                InputField(label: "密码", placeholder: "123456", text: $password, isSecure: true)
            }
            .padding(.horizontal, 30)
            .frame(height: 186)
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
                .frame(width: 60, alignment: .trailing)
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
                Text(isLoading ? "登录中" : "登录")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
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
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.main)
            .frame(maxWidth: .infinity, alignment: .center)
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

#Preview {
    LoginView()
}
