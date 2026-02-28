//
//  BillingSendingView.swift
//  AnuraBilling
//
//  Created by Michael Xu on 2026/2/11.
//

import SwiftUI

struct BillingSendingView: View {
    @Environment(\.presentationMode) var presentationMode
    let orgList: OrgListModel
    @State private var email: String = ""
    @State private var content: String = ""
    let billName = "Nuralogix账单20260127085730"
    let billPeriod = "2020.12.25 ~ 2026.01.27"
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
                                        .frame(width: 50, alignment: .leading)
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
                                    Text("剩余测量成功(次)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .frame(width: 70, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                                // 表格内容
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(orgList.orgs.indices, id: \ .self) { idx in
                                        HStack(alignment: .top) {
                                            Text(orgList.orgs[idx].name)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 50, alignment: .leading)
                                            Text(orgList.orgs[idx].totalDepositsString)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 50, alignment: .leading)
                                            Text(orgList.orgs[idx].periodCostString)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 60, alignment: .leading)
                                            Text(orgList.orgs[idx].totalCostString)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 50, alignment: .leading)
                                            Text(orgList.orgs[idx].balanceString)
                                                .font(.system(size: 8))
                                                .foregroundColor(balanceColor(orgList.orgs[idx].balanceString))
                                                .frame(width: 45, alignment: .leading)
                                            Text(orgList.orgs[idx].unitPriceString)
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 45, alignment: .leading)
                                            Text("\(orgList.orgs[idx].periodSuccess)")
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 80, alignment: .leading)
                                            Text("\(orgList.orgs[idx].successCount)")
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 60, alignment: .leading)
                                            Text("\(orgList.orgs[idx].leftSuccessCount)")
                                                .font(.system(size: 8))
                                                .foregroundColor(.text)
                                                .frame(width: 70, alignment: .leading)
                                        }
                                        .padding(.vertical, 8)
                                        if idx != orgList.orgs.count - 1 {
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
            .onAppear {
                let orgs = orgList.orgs
                let insufficientOrgsCount = orgs.filter { $0.balance < 0 }.count
                let accumulatedSuccess = orgs.reduce(0) { $0 + $1.successCount }
                let accumulatedDeposits = formatAmount(orgs.reduce(0) { $0 + $1.totalDeposits })
                let accumulatedCost = formatAmount(orgs.reduce(0) { $0 + $1.totalCost })
                let accumulatedPeriodSuccess = orgs.reduce(0) { $0 + $1.periodSuccess }
                let accumulatedPeriodCost = formatAmount(orgs.reduce(0) { $0 + $1.periodCost })

                content = """
                    · 组织数：\(orgs.count)个
                    · 余额不足的组织数：\(insufficientOrgsCount)个
                    · 累计测量成功次数：\(accumulatedSuccess)次
                    · 累计充值：\(accumulatedDeposits)元
                    · 累计消费：\(accumulatedCost)元
                    · 周期内测量成功次数：\(accumulatedPeriodSuccess)元
                    · 周期内消费：\(accumulatedPeriodCost)元
                    · 详情请查看附件！
                    """
            }
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
    BillingSendingView(orgList: OrgListModel())
}
