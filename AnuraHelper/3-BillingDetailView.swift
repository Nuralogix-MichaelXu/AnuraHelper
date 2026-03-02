//
//  BillingDetailView.swift
//  AnuraHelper
//
//  Created by Michael Xu on 2026/2/10.
//

import SwiftUI

struct BillingDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var org: OrgInfo
    let period: String
    @State private var showDepositsAlert = false
    @State private var tempDepositsValue = ""
    @State private var showUnitPriceAlert = false
    @State private var tempUnitPriceValue = ""
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    let vSpace: CGFloat = 15.0
                    VStack(alignment: .leading, spacing: 0) {
                        // 顶部返回+标题
                        HStack(spacing: 0) {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(org.name)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.text)
                            Spacer()
                            // 占位保证标题居中
                            Color.clear.frame(width: 18, height: 18)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        
                        // 组织信息区
                        VStack(spacing: vSpace) {
                            HStack(alignment: .center, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text("总充值(元): ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(org.totalDepositsString)
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Image(systemName: "square.and.pencil")
                                        .resizable()
                                        .frame(width: 13, height: 13)
                                        .foregroundColor(.deepPurple)
                                        .padding(.leading, 3)
                                        .padding(.top, -3)
                                        .onTapGesture {
                                            tempDepositsValue = String(org.totalDeposits)
                                            showDepositsAlert = true
                                        }
                                }
                                Spacer(minLength: 0)
                                HStack(spacing: 0) {
                                    Text("单价(元/次): ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(org.unitPriceString)
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Image(systemName: "square.and.pencil")
                                        .resizable()
                                        .frame(width: 13, height: 13)
                                        .foregroundColor(.deepPurple)
                                        .padding(.leading, 3)
                                        .padding(.top, -3)
                                        .onTapGesture {
                                            tempUnitPriceValue = formatUnitPrice(org.unitPrice)
                                            showUnitPriceAlert = true
                                        }
                                }
                            }
                            
                            HStack(alignment: .center, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text("总消费(元): ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(org.totalCostString)
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                }
                                Spacer(minLength: 0)
                                HStack(spacing: 0) {
                                    Text("余额(元): ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(org.balanceString)
                                        .font(.system(size: 12))
                                        .foregroundColor(org.balanceColor)
                                }
                            }
                        }
                        .padding(.top, 35)
                        .padding(.horizontal, 20)
                        
                        // 统计周期
                        VStack(alignment: .leading, spacing: vSpace) {
                            Text("统计周期: \(period)")
                                .font(.system(size: 12))
                                .foregroundColor(.lightBlue)
                            Text("周期内消费(元): \(org.periodCostString)")
                                .font(.system(size: 12))
                                .foregroundColor(.lightBlue)
                        }
                        .padding(.top, vSpace)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            // 许可证表格
                            VStack(spacing: 0) {
                                HStack {
                                    Text("许可证")
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.vertical, 10)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .background(Color(UIColor.systemGray6))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(spacing: 0) {
                                        HStack(spacing: 0) {
                                            Text("创建日期").frame(width: 70, alignment: .leading)
                                            Text("类型").frame(width: 50, alignment: .leading)
                                            Text("设备注册信息").frame(width: 75, alignment: .leading)
                                            Text("状态").frame(width: 50, alignment: .leading)
                                            Text("有效期").frame(width: 65, alignment: .leading)
                                            Text("许可证秘钥").frame(width: 60, alignment: .leading)
                                        }
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .padding(.top, 12)
                                        .padding(.bottom, 4)
                                        .padding(.horizontal, 20)
                                        .background(Color.white)
                                        ForEach(licenses.indices, id: \ .self) { idx in
                                            LicenseRowView(license: licenses[idx])
                                            if idx != licenses.count - 1 {
                                                Divider()
                                                    .background(Color(UIColor.systemGray5))
                                                    .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            
                            // 研究表格
                            VStack(spacing: 0) {
                                HStack {
                                    Text("研究")
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.vertical, 10)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .background(Color(UIColor.systemGray6))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(spacing: 0) {
                                        HStack(spacing: 0) {
                                            Text("创建日期").frame(width: 70, alignment: .leading)
                                            Text("名称").frame(width: 100, alignment: .leading)
                                            Text("状态").frame(width: 50, alignment: .leading)
                                            Text("测量成功(周期内)").frame(width: 70, alignment: .leading)
                                            Text("测量失败(周期内)").frame(width: 70, alignment: .leading)
                                            Text("费用(周期内)").frame(width: 60, alignment: .leading)
                                            Text("测量成功(总)").frame(width: 60, alignment: .leading)
                                            Text("测量失败(总)").frame(width: 60, alignment: .leading)
                                            Text("费用(总)").frame(width: 50, alignment: .leading)
                                            Text("研究ID").frame(width: 60, alignment: .leading)
                                        }
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .padding(.top, 12)
                                        .padding(.bottom, 4)
                                        .padding(.horizontal, 20)
                                        .background(Color.white)
                                        ForEach(studies.indices, id: \ .self) { idx in
                                            let period = periodStudies.indices.contains(idx) ? periodStudies[idx] : studies[idx]
                                            StudyRowView(study: studies[idx], period: period, unitPrice: org.unitPrice)
                                            Divider()
                                                .background(Color(UIColor.systemGray5))
                                                .padding(.horizontal, 20)
                                        }
                                        StudySummaryRowView(
                                            count: studies.count,
                                            totalPeriodSuccessCount: totalPeriodSuccessCount,
                                            totalPeriodFailCount: totalPeriodFailCount,
                                            totalPeriodCost: totalPeriodCost,
                                            totalSuccessCount: totalSuccessCount,
                                            totalFailCount: totalFailCount,
                                            totalCost: totalCost
                                        )
                                    }
                                }
                            }
                            .background(Color.white)
                            Spacer(minLength: 80)
                        }
                    }
                }
            }
          .background(Color.white)
        }
        .navigationBarHidden(true)
        .alert("请输入充值金额", isPresented: $showDepositsAlert, actions: {
            TextField("充值金额", text: $tempDepositsValue)
                .keyboardType(.decimalPad)
            Button("确定") {
                if let newValue = Double(tempDepositsValue) {
                    org.totalDeposits = newValue
                    // 同步更新SharedUsers和UserStorage
                    if let idx = SharedUsers.firstIndex(where: { $0.orgName == org.name }) {
                        var user = SharedUsers[idx]
                        user.deposits = newValue
                        SharedUsers[idx] = user
                        UserStorage.save(users: SharedUsers)
                    }
                }
            }
            Button("取消", role: .cancel) {}
        })
        .alert("请输入单价", isPresented: $showUnitPriceAlert, actions: {
            TextField("单价", text: $tempUnitPriceValue)
                .keyboardType(.decimalPad)
            Button("确定") {
                if let newValue = Double(tempUnitPriceValue) {
                    org.unitPrice = newValue
                    // 同步更新SharedUsers和UserStorage
                    if let idx = SharedUsers.firstIndex(where: { $0.orgName == org.name }) {
                        var user = SharedUsers[idx]
                        user.unitPrice = newValue
                        SharedUsers[idx] = user
                        UserStorage.save(users: SharedUsers)
                    }
                }
            }
            Button("取消", role: .cancel) {}
        })
    }
}

// MARK: - 子视图优化
private struct LicenseRowView: View {
    let license: LicenseResponse
    var body: some View {
        HStack(spacing: 0) {
            Text(license.createdDateString).frame(width: 70, alignment: .leading)
            Text(license.LicenseType).frame(width: 50, alignment: .leading)
            Text(license.DeviceRegistrationString).frame(width: 75, alignment: .leading)
            Text(license.statusString).frame(width: 50, alignment: .leading)
            Text(license.expirationString).frame(width: 65, alignment: .leading)
            Text(license.encryptedKey).frame(width: 60, alignment: .leading)
        }
        .font(.system(size: 8))
        .foregroundColor(.text)
        .padding(.vertical, 6)
        .padding(.leading, 0)
        .background(Color.white)
        .lineLimit(1)
    }
}

private struct StudyRowView: View {
    let study: StudyResponse
    let period: StudyResponse
    let unitPrice: Double
    var body: some View {
        let cost = unitPrice * Double(study.successMeasurements ?? 0)
        let cost_period = unitPrice * Double(period.successMeasurements ?? 0)
        HStack(spacing: 0) {
            Text(study.createdDateString).frame(width: 70, alignment: .leading)
            Text(study.Name).frame(width: 100, alignment: .leading)
            Text(study.statusString).frame(width: 50, alignment: .leading)
            Text("\(period.successMeasurements ?? 0)").frame(width: 70, alignment: .leading)
            Text("\(period.failCount ?? 0)").frame(width: 70, alignment: .leading)
            Text(formatAmount(cost_period)).frame(width: 60, alignment: .leading)
            Text("\(study.successMeasurements ?? 0)").frame(width: 60, alignment: .leading)
            Text("\(study.failCount ?? 0)").frame(width: 60, alignment: .leading)
            Text(formatAmount(cost)).frame(width: 50, alignment: .leading)
            Text(study.encryptedKey).frame(width: 60, alignment: .leading)
        }
        .font(.system(size: 8))
        .foregroundColor(.text)
        .padding(.vertical, 6)
        .padding(.leading, 0)
        .background(Color.white)
        .lineLimit(1)
    }
}

private struct StudySummaryRowView: View {
    let count: Int
    let totalPeriodSuccessCount: Int
    let totalPeriodFailCount: Int
    let totalPeriodCost: Double
    let totalSuccessCount: Int
    let totalFailCount: Int
    let totalCost: Double
    var body: some View {
        HStack(spacing: 0) {
            Text("总计(\(count))").frame(width: 220, alignment: .leading)
            Text("\(totalPeriodSuccessCount)").frame(width: 70, alignment: .leading)
            Text("\(totalPeriodFailCount)").frame(width: 70, alignment: .leading)
            Text(formatAmount(totalPeriodCost)).frame(width: 60, alignment: .leading)
            Text("\(totalSuccessCount)").frame(width: 60, alignment: .leading)
            Text("\(totalFailCount)").frame(width: 60, alignment: .leading)
            Text(formatAmount(totalCost)).frame(width: 50, alignment: .leading)
            Spacer()
        }
        .font(.system(size: 8, weight: .medium))
        .foregroundColor(.text)
        .padding(.vertical, 7)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}

extension BillingDetailView {
    private var studies: [StudyResponse] { org.studies }
    private var periodStudies: [StudyResponse] { org.periodStudies }
    private var licenses: [LicenseResponse] { org.licenses }
    private var totalPeriodSuccessCount: Int {
        periodStudies.reduce(0) { $0 + ($1.successMeasurements ?? 0) }
    }
    private var totalPeriodFailCount: Int {
        periodStudies.reduce(0) { $0 + ($1.failCount ?? 0) }
    }
    private var totalPeriodCost: Double {
        periodStudies.reduce(0) { $0 + org.unitPrice * Double($1.successMeasurements ?? 0) }
    }
    private var totalSuccessCount: Int {
        studies.reduce(0) { $0 + ($1.successMeasurements ?? 0) }
    }
    private var totalFailCount: Int {
        studies.reduce(0) { $0 + ($1.failCount ?? 0) }
    }
    private var totalCost: Double {
        studies.reduce(0) { $0 + org.unitPrice * Double($1.successMeasurements ?? 0) }
    }
}

#Preview {
    BillingDetailView(org:
            .constant(OrgInfo(
                name: "",
                successCount: 0,
                totalDeposits: 0,
                unitPrice: 0,
                periodSuccess: 0,
                licenses:[],
                studies:[],
                periodStudies: [],
            )), period: "2026-01-01 ~ 2026-01-31"
    )
}
