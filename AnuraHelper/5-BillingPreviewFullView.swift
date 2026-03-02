//
//  BillingPreviewFullView.swift
//  AnuraHelper
//
//  Created by Michael Xu on 2026/2/11.
//

import SwiftUI

struct BillingPreviewFullView: View {
    @Environment(\.presentationMode) var presentationMode
    let orgList: OrgListModel

    var body: some View {
        GeometryReader { geo in
            Color(UIColor.systemGray6).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 5) {
                    Text("账单名称: ")
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                    Text(orgList.billingName)
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
                    Text(orgList.billingPeriod)
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                }
                
                let scale: CGFloat = 1.4

                VStack(alignment: .leading, spacing: 0) {
                    // 表头
                    HStack(alignment: .bottom) {
                        Text("组织名称").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                        Text("已充值(元)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                        Text("周期内\n消费(元)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 40*scale, alignment: .leading)
                        Text("总消费(元)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                        Text("余额(元)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 45*scale, alignment: .leading)
                        Text("单价(元)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 45*scale, alignment: .leading)
                        Text("周期内\n测量成功(次)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                        Text("总测量成功(次)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                        Text("剩余测量成功(次)").font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 70*scale, alignment: .leading)
                        Spacer()
                    }
                    .padding(.vertical, 8*scale)

                // 横向滚动表格
                ScrollView(.vertical, showsIndicators: false) {
                        // 表格内容
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(orgList.orgs.indices, id: \ .self) { idx in
                                HStack {
                                    Text(orgList.orgs[idx].name).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].totalDepositsString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].periodCostString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 40*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].totalCostString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].balanceString).font(.system(size: 8*scale)).foregroundColor(orgList.orgs[idx].balanceColor).frame(width: 45*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].unitPriceString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 45*scale, alignment: .leading)
                                    Text("\(orgList.orgs[idx].periodSuccess)").font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                                    Text("\(orgList.orgs[idx].successCount)").font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                                    Text("\(orgList.orgs[idx].leftSuccessCount)").font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 70*scale, alignment: .leading)
                                }
                                .padding(.vertical, 8*scale)
                                if idx != orgList.orgs.count - 1 {
                                    Divider()
                                        .background(Color(UIColor.systemGray5))
                                        .frame(width: 498*scale)
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
}

#Preview {
    BillingPreviewFullView(orgList: OrgListModel())
}
