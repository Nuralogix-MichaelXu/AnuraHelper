//
//  BillingDetailView.swift
//  AnuraBilling
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
                                        .foregroundColor(.lightBlue)
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
                                        .foregroundColor(.lightBlue)
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
                                        .foregroundColor(org.balance < 0 ? .redText : .greenText)
                                }
                            }
                        }
                        .padding(.top, 35)
                        .padding(.horizontal, 20)
                        
                        // 统计周期
                        VStack(alignment: .leading, spacing: vSpace) {
                            Text("统计周期: \(period)")
                                .font(.system(size: 12))
                                .foregroundColor(.text)
                            Text("周期内消费(元): \(org.periodCostString)")
                                .font(.system(size: 12))
                                .foregroundColor(.text)
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
                                        ForEach(org.licenses.indices, id: \ .self) { idx in
                                            let license = org.licenses[idx]
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
                                            if idx != org.licenses.count - 1 {
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
                                        ForEach(org.studies.indices, id: \ .self) { idx in
                                            let study = org.studies[idx]
                                            let study_period = org.periodStudies[idx]
                                            let cost = org.unitPrice * Double(study.successMeasurements ?? 0)
                                            let cost_period = org.unitPrice * Double(study_period.successMeasurements ?? 0)
                                            HStack(spacing: 0) {
                                                Text(study.createdDateString).frame(width: 70, alignment: .leading)
                                                Text(study.Name).frame(width: 100, alignment: .leading)
                                                Text(study.statusString).frame(width: 50, alignment: .leading)
                                                Text("\(study_period.successMeasurements ?? 0)").frame(width: 70, alignment: .leading)
                                                Text("\(study_period.failCount ?? 0)").frame(width: 70, alignment: .leading)
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
                                            Divider()
                                                .background(Color(UIColor.systemGray5))
                                                .padding(.horizontal, 20)
                                        }
                                        
                                        let totalPeriodSuccessCount = org.periodStudies.reduce(0) {
                                            $0 + ( $1.successMeasurements ?? 0 )
                                        }
                                        let totalPeriodFailCount = org.periodStudies.reduce(0) {
                                            $0 + ( $1.failCount ?? 0 )
                                        }
                                        let totalPeriodCost = org.periodStudies.reduce(0) {
                                            $0 + org.unitPrice * Double($1.successMeasurements ?? 0)
                                        }
                                        let totalSuccessCount = org.studies.reduce(0) {
                                            $0 + ( $1.successMeasurements ?? 0 )
                                        }
                                        let totalFailCount = org.studies.reduce(0) {
                                            $0 + ( $1.failCount ?? 0 )
                                        }
                                        let totalCost = org.studies.reduce(0) {
                                            $0 + org.unitPrice * Double($1.successMeasurements ?? 0)
                                        }

                                        // 统计行
                                        HStack(spacing: 0) {
                                            Text("总计(\(org.studies.count))").frame(width: 220, alignment: .leading)
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
                }
            }
            Button("取消", role: .cancel) {}
        })
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
