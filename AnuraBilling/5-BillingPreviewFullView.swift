//
//  BillingPreviewFullView.swift
//  AnuraBilling
//
//  Created by Michael Xu on 2026/2/11.
//

import SwiftUI

struct BillingPreviewFullView: View {
    @Environment(\.presentationMode) var presentationMode

    let billName = "Nuralogix账单20260127085730"
    let billPeriod = "2020.12.25 ~ 2026.01.27"
    let orgs: [OrgRow] = [
        OrgRow(name: "org1", deposits: "100000", periodConsume: "40000", consume: "60000", balance: "40000", price: "1.2", periodSuccess: "30000", success: "50000"),
        OrgRow(name: "org2", deposits: "20000", periodConsume: "2000.5", consume: "2598.4", balance: "17401.6", price: "0.8", periodSuccess: "2000", success: "3248"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356"),
        OrgRow(name: "org3", deposits: "10000", periodConsume: "6990", consume: "12356", balance: "-2356", price: "1.0", periodSuccess: "8940", success: "12356")

    ]
    var body: some View {
        GeometryReader { geo in
            Color(UIColor.systemGray6).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 5) {
                    Text("账单名称: ")
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                    Text(billName)
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                HStack(spacing: 5) {
                    Text("账单周期: ")
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                    Text(billPeriod)
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                }
                
                let scale: CGFloat = 1.5

                VStack(alignment: .leading, spacing: 0) {
                    // 表头
                    HStack {
                        Text("组织名称")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 42*scale, alignment: .leading)
                        Text("已充值(元)")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 50*scale, alignment: .leading)
                        Text("周期内消费(元)")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 60*scale, alignment: .leading)
                        Text("总消费(元)")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 50*scale, alignment: .leading)
                        Text("余额(元)")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 45*scale, alignment: .leading)
                        Text("单价(元)")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 45*scale, alignment: .leading)
                        Text("周期内测量成功(次)")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 80*scale, alignment: .leading)
                        Text("总测量成功(次)")
                            .font(.system(size: 8*scale, weight: .medium))
                            .foregroundColor(.text)
                            .frame(width: 60*scale, alignment: .leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8*scale)

                // 横向滚动表格
                ScrollView(.vertical, showsIndicators: false) {
                        
                        // 表格内容
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(orgs.indices, id: \ .self) { idx in
                                HStack {
                                    Text(orgs[idx].name)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(.text)
                                        .frame(width: 42*scale, alignment: .leading)
                                    Text(orgs[idx].deposits)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(.text)
                                        .frame(width: 50*scale, alignment: .leading)
                                    Text(orgs[idx].periodConsume)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(.text)
                                        .frame(width: 60*scale, alignment: .leading)
                                    Text(orgs[idx].consume)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(.text)
                                        .frame(width: 50*scale, alignment: .leading)
                                    Text(orgs[idx].balance)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(balanceColor(orgs[idx].balance))
                                        .frame(width: 45*scale, alignment: .leading)
                                    Text(orgs[idx].price)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(.text)
                                        .frame(width: 45*scale, alignment: .leading)
                                    Text(orgs[idx].periodSuccess)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(.text)
                                        .frame(width: 80*scale, alignment: .leading)
                                    Text(orgs[idx].success)
                                        .font(.system(size: 8*scale))
                                        .foregroundColor(.text)
                                        .frame(width: 60*scale, alignment: .leading)
                                }
                                .padding(.vertical, 8*scale)
                                if idx != orgs.count - 1 {
                                    Divider()
                                        .background(Color(UIColor.systemGray5))
                                        .frame(width: 460*scale)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.top, 30)
            .padding(.bottom, 10)
            .padding(.leading, 30)
            .rotationEffect(.degrees(-90))
            .frame(width: geo.size.height, height: geo.size.width)
            .position(x: geo.size.width/2, y: geo.size.height/2)
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    func balanceColor(_ balance: String) -> Color {
        if let val = Double(balance), val < 0 {
            return Color.red
        } else {
            return Color.green
        }
    }
}

#Preview {
    BillingPreviewFullView()
}
