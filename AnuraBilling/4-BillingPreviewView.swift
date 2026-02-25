//
//  BillingPreviewView.swift
//  AnuraBilling
//
//  Created by Michael Xu on 2026/2/11.
//

import SwiftUI

struct BillingPreviewView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email: String = ""
    @State private var content: String = "· 组织数：3\n· 余额不足的组织数：1\n· 累计测量成功次数：65048\n· 累计充值：130000元\n· 累计消费：74535.4元\n· 周期内测量成功次数：25002\n· 周期内消费：36420元\n· 详情请查看附件！"
    let billName = "Nuralogix账单20260127085730"
    let billPeriod = "2020.12.25 ~ 2026.01.27"
    let orgs: [OrgRow] = [
        OrgRow(name: "org1", deposits: "100000", periodConsume: "40000", consume: "60000", balance: "40000", price: "1.2", periodSuccess: "30000", success: "50000"),
        OrgRow(name: "org2", deposits: "20000", periodConsume: "2000.5", consume: "2598.4", balance: "17401.6", price: "0.8", periodSuccess: "2000", success: "3248"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356")
    ]
    @State private var showFullPreview = false
    var body: some View {
        NavigationStack{
            VStack(spacing: 0) {
                // 顶部返回按钮
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.leading, 20)
                
                // 标题
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "text.document")
                            .font(.system(size: 18))
                            .foregroundColor(.text)
                        
                        Text("账单预览")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.text)
                    }
                    Spacer()
                }
                .padding(.top, 30)
                
                ZStack(alignment: .topTrailing) {
                    // 账单信息卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 5) {
                            Text("账单名称: ")
                                .font(.system(size: 12))
                                .foregroundColor(.text)
                            
                            Text(billName)
                                .font(.system(size: 12))
                                .foregroundColor(.text)
                        }
                        
                        HStack(spacing: 5) {
                            Text("账单周期: ")
                                .font(.system(size: 12))
                                .foregroundColor(.text)
                            
                            Text(billPeriod)
                                .font(.system(size: 12))
                                .foregroundColor(.text)
                        }
                        
                        // 横向滚动表格
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                // 表头
                                HStack {
                                    Text("组织名称")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 42, alignment: .leading)
                                    Text("已充值(元)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 50, alignment: .leading)
                                    Text("周期内消费(元)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 60, alignment: .leading)
                                    Text("总消费(元)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 50, alignment: .leading)
                                    Text("余额(元)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 45, alignment: .leading)
                                    Text("单价(元)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 45, alignment: .leading)
                                    Text("周期内测量成功(次)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 80, alignment: .leading)
                                    Text("总测量成功(次)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 60, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                                // 表格内容
                                VStack(spacing: 0) {
                                    ForEach(orgs.indices, id: \ .self) { idx in
                                        HStack {
                                            Text(orgs[idx].name)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 42, alignment: .leading)
                                            Text(orgs[idx].deposits)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 50, alignment: .leading)
                                            Text(orgs[idx].periodConsume)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 60, alignment: .leading)
                                            Text(orgs[idx].consume)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 50, alignment: .leading)
                                            Text(orgs[idx].balance)
                                                .font(.system(size: 8))
                                                .foregroundColor(balanceColor(orgs[idx].balance))
                                                .frame(width: 45, alignment: .leading)
                                            Text(orgs[idx].price)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 45, alignment: .leading)
                                            Text(orgs[idx].periodSuccess)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 80, alignment: .leading)
                                            Text(orgs[idx].success)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 60, alignment: .leading)
                                        }
                                        .padding(.vertical, 8)
                                        if idx != orgs.count - 1 {
                                            Divider()
                                                .background(Color(UIColor.systemGray5))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 20)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(5)
                    
                    Image(systemName: "paperclip")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .padding(.trailing, 5)
                        .padding(.top, -5)
                    
                    
                    NavigationLink(destination: BillingPreviewFullView().navigationBarHidden(true)) {
                        Image(systemName: "widget.medium.badge.plus")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.main)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 205)
                }
                .padding(.top, 50)
                .padding(.horizontal, 10)

                Spacer()
                
                // 邮箱和内容输入区
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("发送至邮箱")
                            .font(.system(size: 14))
                            .foregroundColor(.text)
                            .frame(width: 80, alignment: .trailing)
                        Spacer(minLength: 10)
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text(AttributedString("example@gmail.com"))
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(UIColor.systemGray5))
                                    .padding(.horizontal, 10)
                                    .allowsHitTesting(false)
                            }
                            TextField("", text: $email)
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
                        Text("邮件内容")
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
                Button(action: {}) {
                    Text("发送账单")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 140, height: 40)
                        .background(.main)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.6), radius: 5, x: 5, y: 5)
                }
                .padding(.vertical, 40)
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
    }
    func balanceColor(_ balance: String) -> Color {
        if let val = Double(balance), val < 0 {
            return Color.red
        } else {
            return Color.green
        }
    }
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

#Preview {
    BillingPreviewView()
}
