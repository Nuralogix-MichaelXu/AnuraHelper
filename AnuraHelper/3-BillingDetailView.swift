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
    @State private var editingStudy: StudyResponse? = nil // 新增：当前正在编辑的study
    @State private var tempStudyUnitPriceValue = "" // 新增：study单价临时值
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    let vSpace: CGFloat = 15.0
                    VStack(alignment: .leading, spacing: 0) {
                        // 组织信息区
                        VStack(spacing: vSpace) {
                            HStack(alignment: .center, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text(Localized("total_deposits_label") + ": ")
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
                                        .padding(.top, -3.5)
                                        .onTapGesture {
                                            tempDepositsValue = String(org.totalDeposits)
                                            showDepositsAlert = true
                                        }
                                }
                                Spacer(minLength: 0)
                                HStack(spacing: 0) {
                                    Text(Localized("unit_price_label") + ": ")
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
                                        .padding(.top, -3.5)
                                        .onTapGesture {
                                            tempUnitPriceValue = formatUnitPrice(org.unitPrice)
                                            showUnitPriceAlert = true
                                        }
                                }
                            }
                            
                            HStack(alignment: .center, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text(Localized("total_cost_label") + ": ")
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                    Text(org.totalCostString)
                                        .font(.system(size: 12))
                                        .foregroundColor(.text)
                                }
                                Spacer(minLength: 0)
                                HStack(spacing: 0) {
                                    Text(Localized("balance_label") + ": ")
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
                            Text(Localized("period_time") + ": \(period)")
                                .font(.system(size: 12))
                                .foregroundColor(.lightBlue)
                            Text(Localized("period_cost_label") + ": \(org.periodCostString)")
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
                                    Text(Localized("license_table_title"))
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.vertical, 10)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .background(Color(UIColor.systemGray6))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(spacing: 0) {
                                        HStack(alignment: .bottom, spacing: 0) {
                                            Text(Localized("created_date")).frame(width: 70, alignment: .leading)
                                            Text(Localized("license_type")).frame(width: AutoSize(50, 65), alignment: .leading)
                                            Text(Localized("device_registration")).frame(width: AutoSize(75, 85), alignment: .leading)
                                            Text(Localized("status")).frame(width: 50, alignment: .leading)
                                            Text(Localized("expiration")).frame(width: AutoSize(65, 95), alignment: .leading)
                                            Text(Localized("license_key")).frame(width: 60, alignment: .leading)
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
                                .enableSwipeBack()
                            }
                            .background(Color.white)
                            
                            // 研究表格
                            VStack(spacing: 0) {
                                HStack(alignment: .bottom) {
                                    Text(Localized("study_table_title"))
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.vertical, 10)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .background(Color(UIColor.systemGray6))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(spacing: 0) {
                                        HStack(spacing: 0) {
                                            Text(Localized("created_date")).frame(width: 70, alignment: .leading)
                                            Text(Localized("study_name")).frame(width: 90, alignment: .leading)
                                            Text(Localized("status")).frame(width: 50, alignment: .leading)
                                            Text(Localized("unit_price_label")).frame(width: 70, alignment: .leading)
                                            Text(Localized("period_success")).frame(width: AutoSize(60, 85), alignment: .leading)
                                            Text(Localized("period_cost")).frame(width: AutoSize(65, 75), alignment: .leading)
                                            Text(Localized("total_success")).frame(width: AutoSize(55, 80), alignment: .leading)
                                            Text(Localized("total_cost_label")).frame(width: AutoSize(60, 60), alignment: .leading)
                                            Text(Localized("period_fail")).frame(width: 60, alignment: .leading)
                                            Text(Localized("total_fail")).frame(width: 55, alignment: .leading)
                                            Text(Localized("study_id")).frame(width: 60, alignment: .leading)
                                        }
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.text)
                                        .padding(.top, 12)
                                        .padding(.bottom, 4)
                                        .padding(.horizontal, 20)
                                        .background(Color.white)
                                        ForEach(studies.indices, id: \ .self) { idx in
                                            let period = periodStudies.indices.contains(idx) ? periodStudies[idx] : studies[idx]
                                            StudyRowView(
                                                study: studies[idx],
                                                period: period,
                                                unitPrice: studies[idx].unitPrice ?? org.unitPrice,
                                                onEditUnitPrice: { study in
                                                    editingStudy = study
                                                    tempStudyUnitPriceValue = study.unitPrice != nil ? formatUnitPrice(study.unitPrice!) : formatUnitPrice(org.unitPrice)
                                                }
                                            )
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
                                .enableSwipeBack()
                            }
                            .background(Color.white)
                            Spacer(minLength: 80)
                        }
                    }
                }
            }
          .background(Color.white)
        }
        .navigationBarHidden(false)
        .navigationBarTitle(org.name, displayMode: .inline)
        .alert(Localized("input_deposits_title"), isPresented: $showDepositsAlert, actions: {
            TextField(Localized("input_deposits_placeholder"), text: $tempDepositsValue)
                .keyboardType(.decimalPad)
            Button(Localized("confirm")) {
                if let newValue = Double(tempDepositsValue) {
                    org.totalDeposits = newValue
                    if let idx = SharedUsers.firstIndex(where: { $0.orgName == org.name }) {
                        var user = SharedUsers[idx]
                        user.deposits = newValue
                        SharedUsers[idx] = user
                        UserStorage.save(users: SharedUsers)
                    }
                }
            }
            Button(Localized("cancel"), role: .cancel) {}
        })
        // 恢复原有“编辑单价”弹框，只编辑全局单价
        .alert(Localized("input_unit_price_title"), isPresented: $showUnitPriceAlert, actions: {
            TextField(Localized("input_unit_price_placeholder"), text: $tempUnitPriceValue)
                .keyboardType(.decimalPad)
            Button(Localized("confirm")) {
                if let newValue = Double(tempUnitPriceValue) {
                    org.unitPrice = newValue
                    org.resetStudyUnitPrice()
                    org.studies = org.studies // 触发刷新
                    org.periodStudies = org.periodStudies // 触发刷新
                    if let idx = SharedUsers.firstIndex(where: { $0.orgName == org.name }) {
                        var user = SharedUsers[idx]
                        user.unitPrice = newValue
                        user.studyUnitPrices = nil
                        SharedUsers[idx] = user
                        UserStorage.save(users: SharedUsers)
                    }
                }
            }
            Button(Localized("cancel"), role: .cancel) {}
        })
        // 新增：单独编辑study单价弹框
        .alert(Localized("input_unit_price_title"), isPresented: Binding<Bool>(
            get: { editingStudy != nil },
            set: { if !$0 { editingStudy = nil } }
        ), actions: {
            TextField(Localized("input_unit_price_placeholder"), text: $tempStudyUnitPriceValue)
                .keyboardType(.decimalPad)
            Button(Localized("confirm")) {
                if let editingStudy = editingStudy, let newValue = Double(tempStudyUnitPriceValue) {
                    if let idx1 = org.studies.firstIndex(where: { $0.ID == editingStudy.ID }),
                        let idx2 = org.periodStudies.firstIndex(where: { $0.ID == editingStudy.ID }){
                        org.studies[idx1].unitPrice = newValue
                        org.studies = org.studies // 触发刷新
                        org.periodStudies[idx2].unitPrice = newValue
                        org.periodStudies = org.periodStudies // 触发刷新
                        if let idx = SharedUsers.firstIndex(where: { $0.orgName == org.name }) {
                            var user = SharedUsers[idx]
                            var studyUnitPrice = user.studyUnitPrices ?? [:]
                            studyUnitPrice[editingStudy.ID] = newValue
                            user.studyUnitPrices = studyUnitPrice
                            SharedUsers[idx] = user
                            UserStorage.save(users: SharedUsers)
                        }
                    }
                }
                editingStudy = nil
            }
            Button(Localized("cancel"), role: .cancel) {
                editingStudy = nil
            }
        })
    }
}

// MARK: - 子视图优化
private struct LicenseRowView: View {
    let license: LicenseResponse
    var body: some View {
        HStack(spacing: 0) {
            Text(license.createdDateString).frame(width: 70, alignment: .leading)
            Text(license.LicenseType).frame(width: AutoSize(50, 65), alignment: .leading)
            Text(license.DeviceRegistrationString).frame(width: AutoSize(75, 85), alignment: .leading)
            Text(license.statusString).frame(width: 50, alignment: .leading)
            Text(license.expirationString).frame(width: AutoSize(65, 95), alignment: .leading)
            Text(license.encryptedKey).frame(width: 60, alignment: .leading)
        }
        .font(.system(size: 8))
        .foregroundColor(.text)
        .padding(.vertical, 6)
        .padding(.horizontal, 0)
        .background(Color.white)
        .lineLimit(1)
    }
}

private struct StudyRowView: View {
    let study: StudyResponse
    let period: StudyResponse
    let unitPrice: Double
    let onEditUnitPrice: (StudyResponse) -> Void // 新增：编辑单价回调
    var body: some View {
        let cost = (study.unitPrice ?? unitPrice) * Double(study.successMeasurements ?? 0)
        let cost_period = (study.unitPrice ?? unitPrice) * Double(period.successMeasurements ?? 0)
        HStack(spacing: 0) {
            Text(study.createdDateString).frame(width: 70, alignment: .leading)
            Text(study.Name).frame(width: 90, alignment: .leading)
            Text(study.statusString).frame(width: 50, alignment: .leading)
            HStack(spacing: 0) {
                Text(study.unitPrice != nil ? formatUnitPrice(study.unitPrice!) : formatUnitPrice(unitPrice))
                    .frame(width: 20, alignment: .leading)
                Button(action: { onEditUnitPrice(study) }) {
                    Image(systemName: "square.and.pencil")
                        .resizable()
                        .frame(width: 13, height: 13)
                        .foregroundColor(.deepPurple)
                        .padding(.top, -2.5)
                        .padding(.leading, 0)
                }
            }.frame(width: 70, alignment: .leading)
            Text("\(period.successMeasurements ?? 0)").frame(width: AutoSize(60, 85), alignment: .leading)
            Text(formatAmount(cost_period)).frame(width: AutoSize(65, 75), alignment: .leading)
            Text("\(study.successMeasurements ?? 0)").frame(width: AutoSize(60, 80), alignment: .leading)
            Text(formatAmount(cost)).frame(width: AutoSize(55, 60), alignment: .leading)
            Text("\(period.failCount ?? 0)").frame(width: 60, alignment: .leading)
            Text("\(study.failCount ?? 0)").frame(width: 55, alignment: .leading)
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
            Text(Localized("summary_total") + "(\(count))").frame(width: 280, alignment: .leading)
            Text("\(totalPeriodSuccessCount)").frame(width: AutoSize(60, 85), alignment: .leading)
            Text(formatAmount(totalPeriodCost)).frame(width: AutoSize(65, 75), alignment: .leading)
            Text("\(totalSuccessCount)").frame(width: AutoSize(60, 80), alignment: .leading)
            Text(formatAmount(totalCost)).frame(width: 55, alignment: .leading)
            Text("\(totalPeriodFailCount)").frame(width: 60, alignment: .leading)
            Text("\(totalFailCount)").frame(width: AutoSize(50, 60), alignment: .leading)
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
        periodStudies.reduce(0) { $0 + ($1.unitPrice ?? org.unitPrice) * Double($1.successMeasurements ?? 0) }
    }
    private var totalSuccessCount: Int {
        studies.reduce(0) { $0 + ($1.successMeasurements ?? 0) }
    }
    private var totalFailCount: Int {
        studies.reduce(0) { $0 + ($1.failCount ?? 0) }
    }
    private var totalCost: Double {
        studies.reduce(0) { $0 + ($1.unitPrice ?? org.unitPrice) * Double($1.successMeasurements ?? 0) }
    }
}

struct SwipeBackModifier: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: 50)
                        .gesture(
                            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                .onEnded { value in
                                    let translation = value.translation.width
                                    let startX = value.startLocation.x
                                    
                                    if startX < 50 && translation > 80 {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
    }
}

extension View {
    func enableSwipeBack() -> some View {
        self.modifier(SwipeBackModifier())
    }
}

#Preview {
    BillingDetailView(org:
            .constant(OrgInfo(
                name: "111",
                successCount: 0,
                totalDeposits: 0,
                unitPrice: 0.8,
                periodSuccess: 0,
                licenses:[
                    LicenseResponse(Created: 123132323,
                                          StatusID: "111",
                                          Expiration: "1231231123",
                                          MaxDevices: 34,
                                          Key: "121212121",
                                          DeviceRegistrations: 23,
                                          LicenseType: "2")
                ],
                studies:[
                    StudyResponse(Created: 123132323,
                                  ID: "lkjghjajjsdjsjkd",
                                  Name: "te22222st1",
                                  Description: "test demo1",
                                  StatusID: "ACTIVE",
                                  Measurements: 10),
                    StudyResponse(Created: 123132323,
                                  ID: "lkjghjajjsdjsjkd",
                                  Name: "tes333t2",
                                  Description: "test demo2",
                                  StatusID: "ACTIVE",
                                  Measurements: 10),
                    StudyResponse(Created: 123132323,
                                  ID: "lkjghjajjsdjsjkd",
                                  Name: "test3",
                                  Description: "test demo3",
                                  StatusID: "DELETED",
                                  Measurements: 10)
                ],
                periodStudies: [],
            )), period: "2026.01.01 ~ 2026.01.31"
    )
}
