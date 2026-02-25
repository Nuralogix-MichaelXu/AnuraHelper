//
//  BillingDetailView.swift
//  AnuraBilling
//
//  Created by Michael Xu on 2026/2/10.
//

import SwiftUI

struct BillingDetailView: View {
    let org: OrgInfo
    @Environment(\.presentationMode) private var presentationMode
    
    // 示例数据
    let orgName = "org1"
    let deposits = "200000"
    let unitPrice = "0.8"
    let totalCost = "28272"
    let balance = "181152"
    let period = "2020.12.25 ~ 2020.12.25"
    let periodCost = "28272"
    let licenseList = [
        ["2026-01-25", "MOBILE", "200/无限使用", "有效", "剩余250天", "1bb1****2136"],
        ["2026-01-25", "MOBILE", "15/200", "已过期", "已过期20天", "2bb1****2136"]
    ]
    let researchList = [
        ["2026-01-25", "Shanghai Medicine", "有效", "3000", "50", "2400", "5000", "80", "4000", "3bb1****2136"],
        ["2026-01-25", "雀巢咖啡2", "有效", "1000", "40", "1000", "3000", "80", "3000", "4bb1****2136"],
        ["2026-01-25", "测试", "已删除", "20", "1", "20", "20", "1", "20", "5bb1****2136"],
    ]
    
    @State private var showDepositsAlert = false
    @State private var depositsValue = ""
    @State private var tempDepositsValue = ""
    @State private var showUnitPriceAlert = false
    @State private var unitPriceValue = ""
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
                            Text("\(orgName)")
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
                                    Text(deposits)
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Image(systemName: "square.and.pencil")
                                        .resizable()
                                        .frame(width: 13, height: 13)
                                        .foregroundColor(.lightBlue)
                                        .padding(.leading, 3)
                                        .padding(.top, -3)
                                        .onTapGesture {
                                            tempDepositsValue = depositsValue
                                            showDepositsAlert = true
                                        }
                                }
                                Spacer(minLength: 0)
                                HStack(spacing: 0) {
                                    Text("单价(元/次): ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(unitPrice)
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Image(systemName: "square.and.pencil")
                                        .resizable()
                                        .frame(width: 13, height: 13)
                                        .foregroundColor(.lightBlue)
                                        .padding(.leading, 3)
                                        .padding(.top, -3)
                                        .onTapGesture {
                                            tempUnitPriceValue = unitPriceValue
                                            showUnitPriceAlert = true
                                        }
                                }
                            }
                            
                            HStack(alignment: .center, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text("总消费(元): ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(totalCost)
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                }
                                Spacer(minLength: 0)
                                HStack(spacing: 0) {
                                    Text("余额(元): ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(balance)
                                        .font(.system(size: 12))
                                        .foregroundColor(.greenText)
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
                            Text("周期内消费(元): \(periodCost)")
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
                                        ForEach(licenseList.indices, id: \ .self) { idx in
                                            let row = licenseList[idx]
                                            HStack(spacing: 0) {
                                                Text(row[0]).frame(width: 70, alignment: .leading)
                                                Text(row[1]).frame(width: 50, alignment: .leading)
                                                Text(row[2]).frame(width: 75, alignment: .leading)
                                                Text(row[3]).frame(width: 50, alignment: .leading)
                                                Text(row[4]).frame(width: 65, alignment: .leading)
                                                Text(row[5]).frame(width: 60, alignment: .leading)
                                            }
                                            .font(.system(size: 8))
                                            .foregroundColor(.text)
                                            .padding(.vertical, 6)
                                            .padding(.leading, 0)
                                            .background(Color.white)
                                            .lineLimit(1)
                                            if idx != licenseList.count - 1 {
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
                                        ForEach(researchList, id: \ .self) { row in
                                            HStack(spacing: 0) {
                                                Text(row[0]).frame(width: 70, alignment: .leading)
                                                Text(row[1]).frame(width: 100, alignment: .leading)
                                                Text(row[2]).frame(width: 50, alignment: .leading)
                                                Text(row[3]).frame(width: 70, alignment: .leading)
                                                Text(row[4]).frame(width: 70, alignment: .leading)
                                                Text(row[5]).frame(width: 60, alignment: .leading)
                                                Text(row[6]).frame(width: 60, alignment: .leading)
                                                Text(row[7]).frame(width: 60, alignment: .leading)
                                                Text(row[8]).frame(width: 50, alignment: .leading)
                                                Text(row[9]).frame(width: 60, alignment: .leading)
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
                                        // 统计行
                                        HStack(spacing: 0) {
                                            Text("总计(3)").frame(width: 220, alignment: .leading)
                                            Text("4020").frame(width: 70, alignment: .leading)
                                            Text("91").frame(width: 70, alignment: .leading)
                                            Text("3420").frame(width: 60, alignment: .leading)
                                            Text("8020").frame(width: 60, alignment: .leading)
                                            Text("161").frame(width: 60, alignment: .leading)
                                            Text("7020").frame(width: 50, alignment: .leading)
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
                
                // 右下角刷新按钮
                Button(action: {}) {
                    Text("刷新")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.deepPurple)
                        .clipShape(Circle())
                        .shadow(color: .gray.opacity(0.6), radius: 5, x: 5, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .navigationBarHidden(true)
        .alert("请输入充值金额", isPresented: $showDepositsAlert, actions: {
            TextField("充值金额", text: $tempDepositsValue)
                .keyboardType(.decimalPad)
            Button("确定") {
                depositsValue = tempDepositsValue
            }
            Button("取消", role: .cancel) {}
        })
        .alert("请输入单价", isPresented: $showUnitPriceAlert, actions: {
            TextField("单价", text: $tempUnitPriceValue)
                .keyboardType(.decimalPad)
            Button("确定") {
                unitPriceValue = tempUnitPriceValue
            }
            Button("取消", role: .cancel) {}
        })
    }
}

#Preview {
    BillingDetailView(org:
                        OrgInfo(
                            name: "",
                            licenseCount: 0,
                            studyCount: 0,
                            successCount: 0,
                            totalDeposits: 0,
                            unitPrice: 0,
                            totalCost: 0,
                            balance: 0,
                            periodSuccess: 0,
                            periodCost: 0
                        )
    )
}
