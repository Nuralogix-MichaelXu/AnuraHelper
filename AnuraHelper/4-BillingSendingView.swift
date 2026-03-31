//
//  BillingSendingView.swift
//  AnuraHelper
//
//  Created by Michael Xu on 2026/2/11.
//

import SwiftUI
import UIKit
import MessageUI
import Combine

class EmailInfo: ObservableObject {
    @Published var toEmail: String = ""
    @Published var mailHTMLBody: String = ""
    @Published var title: String = ""
    
    init(toEmail: String = "", mailHTMLBody: String = "", title: String = "") {
        self.toEmail = toEmail
        self.mailHTMLBody = mailHTMLBody
        self.title = title
    }
}

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.5))
            .cornerRadius(16)
            .shadow(radius: 8)
    }
}

struct BillingSendingView: View {
    @Environment(\.presentationMode) var presentationMode
    let orgList: OrgListModel
    @State private var content: String = ""
    @State private var showFullPreview = false
    @State private var showMail = false
    @ObservedObject private var emailInfo = EmailInfo()
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // 邮箱格式校验
    func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    var body: some View {
        NavigationStack{
            ZStack {
                VStack(spacing: 0) {
                    // 标题
                    Text(Localized("mail_settings_title"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.text)
                        .padding(.top, 30)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ZStack(alignment: .topTrailing) {
                        // 账单信息卡片
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 5) {
                                Text(Localized("bill_name_label"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.text)
                                
                                Text(orgList.billingName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.text)
                            }
                            
                            HStack(spacing: 5) {
                                Text(Localized("bill_period_label"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.text)
                                
                                Text(orgList.billingPeriod)
                                    .font(.system(size: 12))
                                    .foregroundColor(.text)
                            }
                            
                            // 横向滚动表格
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 0) {
                                    // 表头
                                    HStack {
                                        Text(Localized("org_name_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                        Text(Localized("total_deposits_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                                        Text(Localized("period_cost_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                        Text(Localized("total_cost_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                                        Text(Localized("balance_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: AutoSize(45, 55), alignment: .leading)
                                        Text(Localized("unit_price_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 65, alignment: .leading)
                                        Text(Localized("period_success_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: AutoSize(80, 60), alignment: .leading)
                                        Text(Localized("success_count_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                        Text(Localized("left_success_count_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: AutoSize(70, 60), alignment: .leading)
                                        Text(Localized("billing_date")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    let orgs = Array(orgList.orgs.prefix(3))
                                    // 表格内容
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(orgs.indices, id: \ .self) { idx in
                                            HStack(alignment: .top) {
                                                Text(orgs[idx].name).font(.system(size: 8)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                                Text(orgs[idx].totalDepositsString).font(.system(size: 8)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                                                Text(orgs[idx].periodCostString).font(.system(size: 8)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                                Text(orgs[idx].totalCostString).font(.system(size: 8)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                                                Text(orgs[idx].balanceString).font(.system(size: 8)).foregroundColor(orgs[idx].balanceColor).frame(width: AutoSize(45, 55), alignment: .leading)
                                                Text(orgs[idx].unitPriceString).font(.system(size: 8)).foregroundColor(.text).frame(width: 65, alignment: .leading)
                                                Text("\(orgs[idx].periodSuccess)").font(.system(size: 8)).foregroundColor(.text).frame(width: AutoSize(80, 60), alignment: .leading)
                                                Text("\(orgs[idx].successCount)").font(.system(size: 8)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                                Text("\(orgs[idx].leftSuccessCount)").font(.system(size: 8)).foregroundColor(.text).frame(width: AutoSize(70, 60), alignment: .leading)
                                                Text(orgs[idx].billingDate.yyyyMMddDateString).font(.system(size: 8)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                                            }
                                            .padding(.vertical, 8)
                                            if idx != orgs.count - 1 {
                                                Divider()
                                                    .background(Color(UIColor.systemGray5))
                                            }
                                        }
                                        if orgList.orgs.count > 3 {
                                            HStack {
                                                Text("...")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.text)
                                                    .frame(width: 50, alignment: .leading)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .frame(height: 100)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 20)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(5)
                        
                        Image(systemName: "paperclip")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.trailing, 5)
                            .padding(.top, -5)
                        
                        
                        NavigationLink(destination: BillingPreviewFullView(orgList: orgList).navigationBarHidden(true)) {
                            Image(systemName: "widget.medium.badge.plus")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.main)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 205 + (LanguageManager.shared.isCNLanguage() ? 0 : 10))
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 10)
                    
                    Spacer()
                    
                    // 邮箱和内容输入区
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text(Localized("send_to_email_label"))
                                .font(.system(size: 14))
                                .foregroundColor(.text)
                                .frame(width: 80, alignment: .trailing)
                            Spacer(minLength: 10)
                            ZStack(alignment: .leading) {
                                if emailInfo.toEmail.isEmpty {
                                    Text(Localized("send_to_email_placeholder"))
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(UIColor.systemGray5))
                                        .padding(.horizontal, 10)
                                        .allowsHitTesting(false)
                                }
                                TextField("", text: $emailInfo.toEmail)
                                    .font(.system(size: 14))
                                    .foregroundColor(.text)
                                    .padding(10)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray, lineWidth: 1 / UIScreen.main.scale)
                            )
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Text(Localized("mail_content_label"))
                                .font(.system(size: 14))
                                .foregroundColor(.text)
                                .frame(width: 80, alignment: .trailing)
                            TextEditor(text: $content)
                                .font(.system(size: 10))
                                .padding(.vertical, 10)
                                .padding(.leading, 8)
                                .foregroundColor(.text)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.gray, lineWidth: 1 / UIScreen.main.scale)
                                )
                                .frame(height: 140)
                        }
                    }
                    .padding(.top, 48)
                    .padding(.leading, 20)
                    .padding(.trailing, 60)
                    
                    // 发送账单按钮
                    Button(action: {
                        if !isValidEmail(emailInfo.toEmail) {
                            toastMessage = Localized("invalid_email_format")
                            withAnimation { showToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showToast = false }
                            }
                            return
                        }
                        let cardView = BillingPreview(list: orgList.orgs, billName: orgList.billingName, billPeriod: orgList.billingPeriod)
                        let image = cardView.asUIImage(size: CGSize(width: 680, height: 120 + 26 * orgList.orgs.count))
                        // 1. 转为 base64
                        guard let imageData = image.jpegData(compressionQuality: 0.95) else { return }
                        let base64 = imageData.base64EncodedString()
                        let imgTag = "<img src=\"data:image/jpeg;base64,\(base64)\" style=\"max-width:100%;border-radius:8px;\">"
                        var logoTag = ""
                        if let logo = UIImage(named: "companyLogo")?.withBackground(color: .white),
                           let logoData = logo.jpegData(compressionQuality: 0.95) {
                            let logoBase64 = logoData.base64EncodedString()
                            logoTag = "<div style=\"margin-top:50px;text-align:left;\"><img src=\"data:image/jpeg;base64,\(logoBase64)\" style=\"max-width:120px;\"></div>"
                        }

                        // 3. 拼接 HTML 内容
                        let htmlBody = """
                        <div style="font-size:15px;line-height:1.7;color:#222;padding:24px;">
                            \(content.replacingOccurrences(of: "\n", with: "<br>"))<br><br>
                            \(imgTag)
                            \(logoTag)
                        </div>
                        """
                        emailInfo.mailHTMLBody = htmlBody
                        emailInfo.title = orgList.billingName
                        showMail = true
                    }) {
                        Text(Localized("send_bill_button"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 140, height: 40)
                            .background(.main)
                            .opacity((emailInfo.toEmail.isEmpty || content.isEmpty) ? 0.5 : 1)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.6), radius: 5, x: 5, y: 5)
                    }
                    .padding(.vertical, 40)
                    .disabled(emailInfo.toEmail.isEmpty || content.isEmpty)
                }
                .background(Color.white)
                .navigationBarHidden(true)
                .onAppear {
                    let orgs = orgList.orgs
                    let insufficientOrgsCount = orgs.filter { $0.balance < 0 }.count
                    let accumulatedSuccess = orgs.reduce(0) { $0 + $1.successCount }
                    let accumulatedDeposits = formatAmount(orgs.reduce(0) { $0 + $1.totalDeposits })
                    let accumulatedCost = formatAmount(orgs.reduce(0) { $0 + $1.totalCost })
                    let accumulatedPeriodSuccess = orgs.reduce(0) { $0 + $1.periodSuccess }
                    let accumulatedPeriodCost = formatAmount(orgs.reduce(0) { $0 + $1.periodCost })
                    
                    content = """
                        · \(Localized("org_count_label"))：\(orgs.count)
                        · \(Localized("insufficient_org_count_label"))：\(insufficientOrgsCount)
                        · \(Localized("accumulated_success_label"))：\(accumulatedSuccess)
                        · \(Localized("accumulated_deposits_label"))：\(accumulatedDeposits)
                        · \(Localized("accumulated_cost_label"))：\(accumulatedCost)
                        · \(Localized("accumulated_period_success_label"))：\(accumulatedPeriodSuccess)
                        · \(Localized("accumulated_period_cost_label"))：\(accumulatedPeriodCost)
                        """
                }
                // Toast overlay
                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage)
                            .padding(.bottom, 80)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .onTapGesture {
                resignFirstResponder()
            }
        }
        .navigationBarHidden(false)
        .sheet(isPresented: $showMail) {
            if MFMailComposeViewController.canSendMail() {
                MailView(
                    recipients: emailInfo.toEmail.components(separatedBy: ";"),
                    subject: emailInfo.title,
                    htmlBody: emailInfo.mailHTMLBody,
                    resultHandler: { result in
                        mailResult = result
                        // 处理toast
                        switch result {
                        case .success(let mailResult):
                            switch mailResult {
                            case .sent:
                                toastMessage = Localized("mail_sent_success")
                            case .saved:
                                toastMessage = Localized("mail_saved_draft")
                            case .cancelled:
                                toastMessage = Localized("mail_send_cancelled")
                            case .failed:
                                toastMessage = Localized("mail_send_failed")
                            @unknown default:
                                toastMessage = Localized("mail_send_unknown")
                            }
                        case .failure(_):
                            toastMessage = Localized("mail_send_failed")
                        }
                        withAnimation {
                            showToast = true
                        }
                        // 3秒后自动消失
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
                )
            } else {
                VStack(spacing: 20) {
                    Text(Localized("mail_send_unavailable"))
                    Button(Localized("close")) { showMail = false }
                }.padding()
            }
        }
    }
    
    func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 邮件发送视图
struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    var recipients: [String]
    var subject: String
    var htmlBody: String
    var resultHandler: ((Result<MFMailComposeResult, Error>) -> Void)?
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        init(_ parent: MailView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.resultHandler?(error == nil ? .success(result) : .failure(error!))
            parent.presentation.wrappedValue.dismiss()
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(htmlBody, isHTML: true)
        return vc
    }
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

struct OrgRow: Identifiable {
    let id = UUID()
    let name: String
    let deposits: String
    let periodConsume: String
    let consume: String
    let balance: String
    let price: String
    let periodSuccess: String
    let success: String
}

struct BillingPreview: View {
    let list: [OrgInfo]
    let billName: String
    let billPeriod: String
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 5) {
                Text(Localized("bill_name_label"))
                    .font(.system(size: 12))
                    .foregroundColor(.text)
                Text(billName)
                    .font(.system(size: 12))
                    .foregroundColor(.text)
            }
            HStack(spacing: 5) {
                Text(Localized("bill_period_label"))
                    .font(.system(size: 12))
                    .foregroundColor(.text)
                Text(billPeriod)
                    .font(.system(size: 12))
                    .foregroundColor(.text)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(Localized("org_name_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                        Text(Localized("total_deposits_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                        Text(Localized("period_cost_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                        Text(Localized("total_cost_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                        Text(Localized("balance_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 45, alignment: .leading)
                        Text(Localized("unit_price_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 65, alignment: .leading)
                        Text(Localized("period_success_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 80, alignment: .leading)
                        Text(Localized("success_count_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                        Text(Localized("left_success_count_label")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                        Text(Localized("billing_date")).font(.system(size: 8, weight: .medium)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                    }
                    .padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(list.indices, id: \ .self) { idx in
                            HStack(alignment: .top) {
                                Text(list[idx].name).font(.system(size: 8)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                Text(list[idx].totalDepositsString).font(.system(size: 8)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                                Text(list[idx].periodCostString).font(.system(size: 8)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                Text(list[idx].totalCostString).font(.system(size: 8)).foregroundColor(.text).frame(width: 50, alignment: .leading)
                                Text(list[idx].balanceString).font(.system(size: 8)).foregroundColor(.text).frame(width: 45, alignment: .leading)
                                Text(list[idx].unitPriceString).font(.system(size: 8)).foregroundColor(.text).frame(width: 65, alignment: .leading)
                                Text("\(list[idx].periodSuccess)").font(.system(size: 8)).foregroundColor(.text).frame(width: 80, alignment: .leading)
                                Text("\(list[idx].successCount)").font(.system(size: 8)).foregroundColor(.text).frame(width: 60, alignment: .leading)
                                Text("\(list[idx].leftSuccessCount)").font(.system(size: 8)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                                Text(list[idx].billingDate.yyyyMMddDateString).font(.system(size: 8)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                            }
                            .padding(.vertical, 8)
                            if idx != list.count - 1 {
                                Divider().background(Color(UIColor.systemGray5))
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 20)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(5)
    }
}

extension View {
    func asUIImage(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea() // 关键：忽略安全区
        )
        let view = controller.view
        let targetSize = size
        let window = UIWindow(frame: CGRect(origin: .zero, size: targetSize))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        view?.bounds = window.bounds
        view?.backgroundColor = .clear // 可选：背景透明
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
}

#Preview {
    let orgs1: OrgListModel = {
        var study1 = StudyResponse(Created: 123132323,
                                  ID: "lkjghjajjsdjsjkd",
                                  Name: "te22222st1",
                                  Description: "test demo1",
                                  StatusID: "ACTIVE",
                                  Measurements: 10)
        study1.unitPrice = 1.2
        
        var study2 = StudyResponse(Created: 123132323,
                                  ID: "lkjghjajjsdjsjkd",
                                  Name: "te22222st1",
                                  Description: "test demo1",
                                  StatusID: "ACTIVE",
                                  Measurements: 10)
        study2.unitPrice = 1.0


        let orgs1 = OrgListModel()
        let org = OrgInfo(
            key: "1110",
            region: .china,
            name: "123",
            successCount: 20,
            totalDeposits: 30,
            unitPrice: 1,
            periodSuccess: 10,
            billingDate: Date(),
            startDate: Date(),
            endDate: Date(),
            studies:[
                study1,
                study2
            ]
        )
        orgs1.orgs = [org, org]
        return orgs1
    }()
    return BillingSendingView(orgList: orgs1)
}
