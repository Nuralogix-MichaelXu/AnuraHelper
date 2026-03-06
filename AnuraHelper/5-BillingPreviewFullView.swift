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
                    Text(Localized("bill_name_label"))
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
                    Text(Localized("bill_period_label"))
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                    Text(orgList.billingPeriod)
                        .font(.system(size: 12))
                        .foregroundColor(.text)
                }
                
                let scale: CGFloat = 1.2

                VStack(alignment: .leading, spacing: 0) {
                    // 表头
                    HStack(alignment: .bottom) {
                        Text(Localized("org_name_label")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                        Text(Localized("total_deposits_label")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                        Text(Localized("period_cost_label2")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 40*scale, alignment: .leading)
                        Text(Localized("total_cost_label")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 45*scale, alignment: .leading)
                        Text(Localized("balance_label")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: AutoSize(40, 55)*scale, alignment: .leading)
                        Text(Localized("unit_price_label")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                        Text(Localized("period_success_label2")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                        Text(Localized("success_count_label")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                        Text(Localized("left_success_count_label")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: AutoSize(70, 60)*scale, alignment: .leading)
                        Text(Localized("billing_date")).font(.system(size: 8*scale, weight: .medium)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                        Spacer()
                    }
                    .padding(.vertical, 8*scale)

                // 横向滚动表格
                ScrollView(.vertical, showsIndicators: false) {
                        // 表格内容
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(orgList.orgs.indices, id: \ .self) { idx in
                                HStack {
                                    Text(orgList.orgs[idx].name).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].totalDepositsString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].periodCostString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 40*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].totalCostString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 45*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].balanceString).font(.system(size: 8*scale)).foregroundColor(orgList.orgs[idx].balanceColor).frame(width: AutoSize(40, 55)*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].unitPriceString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                                    Text("\(orgList.orgs[idx].periodSuccess)").font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 50*scale, alignment: .leading)
                                    Text("\(orgList.orgs[idx].successCount)").font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 60*scale, alignment: .leading)
                                    Text("\(orgList.orgs[idx].leftSuccessCount)").font(.system(size: 8*scale)).foregroundColor(.text).frame(width: AutoSize(70, 60)*scale, alignment: .leading)
                                    Text(orgList.orgs[idx].billingDate.yyyyMMddDateString).font(.system(size: 8*scale)).foregroundColor(.text).frame(width: 70, alignment: .leading)
                                }
                                .padding(.vertical, 8*scale)
                                if idx != orgList.orgs.count - 1 {
                                    Divider()
                                        .background(Color(UIColor.systemGray5))
                                        .padding(.trailing, 20*scale)
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
    let orgs1: OrgListModel = {
        let orgs1 = OrgListModel()
        let org = OrgInfo(
            region: .china,
            name: "",
            successCount: 0,
            totalDeposits: 0,
            unitPrice: 1,
            periodSuccess: 0,
            billingDate: Date(),
            startDate: Date(),
            endDate: Date(),
            licenses: [LicenseResponse(Created: 123132323, StatusID: "111", Expiration: "1231231123", MaxDevices: 34, Key: "121212121", DeviceRegistrations: 23, LicenseType: "2")],
            studies: [],
        )
        orgs1.orgs = [org, org]
        return orgs1
    }()
    return BillingPreviewFullView(orgList: orgs1)
}
