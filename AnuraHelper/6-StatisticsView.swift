//
//  StatisticsView.swift
//  AnuraHelper
//
//  Created by Michael Xu on 2026/4/17.
//

import SwiftUI

struct StatisticsView: View {
    @ObservedObject var orgList: OrgListModel
    @State private var selectedTab: StatisticsTab = .bill
    @Environment(\.dismiss) private var dismiss

    private var companyAggregates: [CompanyAggregate] {
        var map: [String: CompanyAggregate] = [:]

        for org in orgList.orgs {
            let company = Self.companyName(from: org.name)
            var aggregate = map[company] ?? CompanyAggregate(name: company, billingDate: org.billingDate)

            for study in org.studies {
                var successCount = study.billingSuccessMeasurements ?? study.totalSuccessMeasurements ?? 0
                var cost = study.billingCost
                if selectedTab == .custom {
                    successCount = study.periodSuccessMeasurements ?? study.totalSuccessMeasurements ?? 0
                    cost = study.periodCost ?? 0
                }

                if Self.is5sStudy(study.Name) {
                    aggregate.count5s += successCount
                    aggregate.cost5s += cost
                } else {
                    aggregate.count30s += successCount
                    aggregate.cost30s += cost
                }
            }

            map[company] = aggregate
        }

        return map.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var organizations: [OrgStatItem] {
        companyAggregates.map { aggregate in
            OrgStatItem(
                name: aggregate.name,
                fastCount: formatCount(aggregate.count30s),
                fastCost: formatAmount(aggregate.cost30s),
                slowCount: formatCount(aggregate.count5s),
                slowCost: formatAmount(aggregate.cost5s),
                totalCount: formatCount(aggregate.totalCount),
                totalCost: formatAmount(aggregate.totalCost),
                billingDate: aggregate.billingDate
            )
        }.sorted { $0.totalCost < $1.totalCost }
    }

    private var summary: StatisticsSummary {
        let totalCompanies = companyAggregates.count
        let total30sCount = companyAggregates.reduce(0) { $0 + $1.count30s }
        let total5sCount = companyAggregates.reduce(0) { $0 + $1.count5s }
        let totalCount = total30sCount + total5sCount

        let total30sCost = companyAggregates.reduce(0.0) { $0 + $1.cost30s }
        let total5sCost = companyAggregates.reduce(0.0) { $0 + $1.cost5s }
        let totalCost = total30sCost + total5sCost

        return StatisticsSummary(
            totalCompanies: totalCompanies,
            fastCount: formatCount(total30sCount),
            fastCost: formatAmount(total30sCost),
            slowCount: formatCount(total5sCount),
            slowCost: formatAmount(total5sCost),
            totalCount: formatCount(totalCount),
            totalCost: formatAmount(totalCost)
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if !orgList.isPeriodNone { topSegment }
                if selectedTab == .custom { dateBar }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        SummaryCardView(summary: summary)

                        ForEach(Array(organizations.enumerated()), id: \.element.id) { index, item in
                            OrgStatCardView(index: index + 1, item: item, isBilling: selectedTab == .bill )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .padding(.horizontal, 8)
                    .padding(.top, 5)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, UIDevice.current.isIPad ? 10 : 5)
        }
        .navigationTitle(Localized("statistics_billing_title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
    }

    private var topSegment: some View {
        HStack(spacing: 0) {
            Spacer()

            HStack(spacing: 0) {
                segmentButton(title: Localized("statistics_tab_billing"), tab: .bill)
                segmentButton(title: Localized("statistics_tab_custom_period"), tab: .custom)
            }
            .frame(width: 227, height: 32)
            .background(.subBackgound)
            .cornerRadius(10)

            Spacer()
        }
        .padding(.top, 10)
    }

    private func segmentButton(title: String, tab: StatisticsTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            ZStack {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(.thirdBackgound)
                        .padding(2)
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : .text)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(1)
    }
    
    private var dateBar: some View {
        Text(orgList.billingPeriod)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.text)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(.thirdBackgound.opacity(0.5))
            .padding(.top, 15)
    }

    private static func companyName(from orgName: String) -> String {
        let parts = orgName.split(separator: "_", maxSplits: 1, omittingEmptySubsequences: false)
        let prefix = parts.first.map(String.init) ?? orgName
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? orgName : trimmed
    }

    private static func is5sStudy(_ studyName: String) -> Bool {
        studyName.range(of: "5s", options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

private struct SummaryCardView: View {
    let summary: StatisticsSummary

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(.thirdBackgound.opacity(0.25))
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        Text("\(Localized("statistics_total_prefix"))(\(summary.totalCompanies))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.text)
                    )
                
                NavigationLink {
                    AnalysisView()
                } label: {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFFFFFF))
                        .frame(width: 20, height: 16)
                        .padding(2)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.thirdBackgound)
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                MeasureBlockView(title: Localized("statistics_30s_measurement"), count: summary.fastCount, cost: summary.fastCost)
                MeasureBlockView(title: Localized("statistics_5s_measurement"), count: summary.slowCount, cost: summary.slowCost)
                MeasureBlockView(title: Localized("statistics_all_measurement"), count: summary.totalCount, cost: summary.totalCost)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 20)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private struct OrgStatCardView: View {
    let index: Int
    let item: OrgStatItem
    let isBilling: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(index). \(Localized("statistics_company_name")): \(item.name)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.text)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(.thirdBackgound.opacity(0.25))
                    )
                    .fixedSize(horizontal: true, vertical: false)

                NavigationLink {
                    AnalysisView(companyName: item.name)
                } label: {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFFFFFF))
                        .frame(width: 20, height: 16)
                        .padding(2)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.thirdBackgound)
                        )
                }
                .buttonStyle(.plain)
                
                Spacer()

                if isBilling {
                    Text(Localized("billing_date") + ": " + item.billingDate.yyyyMMddDateString)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.subText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .padding([.top, .trailing], 2)
                }
            }
            
            Divider()
                .background(.thirdBackgound.opacity(0.1))

            HStack(spacing: 8) {
                MeasureBlockView(title: Localized("statistics_30s_measurement"), count: item.fastCount, cost: item.fastCost)
                MeasureBlockView(title: Localized("statistics_5s_measurement"), count: item.slowCount, cost: item.slowCost)
                MeasureBlockView(title: Localized("statistics_all_measurement"), count: item.totalCount, cost: item.totalCost)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private struct MeasureBlockView: View {
    let title: String
    let count: String
    let cost: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.text)

            VStack(alignment: .leading, spacing: 10) {
                Text("\(Localized("measurement_count"))\(count)")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(.subText)
                Text("\(Localized("measurement_cost"))\(cost)")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(.subText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.thirdBackgound.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private enum StatisticsTab {
    case bill
    case custom
}

private struct StatisticsSummary {
    let totalCompanies: Int
    let fastCount: String
    let fastCost: String
    let slowCount: String
    let slowCost: String
    let totalCount: String
    let totalCost: String
}

private struct OrgStatItem: Identifiable {
    let id = UUID()
    let name: String
    let fastCount: String
    let fastCost: String
    let slowCount: String
    let slowCost: String
    let totalCount: String
    let totalCost: String
    let billingDate: Date
}

private struct CompanyAggregate {
    let name: String
    let billingDate: Date
    var count30s: Int = 0
    var cost30s: Double = 0
    var count5s: Int = 0
    var cost5s: Double = 0

    var totalCount: Int { count30s + count5s }
    var totalCost: Double { cost30s + cost5s }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

#Preview {
    // Preview-only mock data to make StatisticsView render without requiring live network data.
    let previewModel: OrgListModel = {
        let model = OrgListModel()

        let now = Date()

        func makeStudy(id: String, name: String, unitPrice: Double, billingSuccess: Int, periodSuccess: Int) -> StudyResponse {
            let s = StudyResponse(
                Created: UInt(now.timeIntervalSince1970),
                ID: id,
                Name: name,
                Description: "",
                StatusID: "ACTIVE",
                Measurements: 0,
                TotalCount: nil,
                totalSuccessMeasurements: nil,
                periodSuccessMeasurements: periodSuccess,
                billingSuccessMeasurements: billingSuccess,
                periodBillingSuccessMeasurements: nil,
                isPerioContainBilling: nil,
                unitPrice: unitPrice
            )
            return s
        }

        func makeOrg(key: String, name: String, billingDate: Date, studies: [StudyResponse], totalDeposits: Double, unitPrice: Double) -> OrgInfo {
            OrgInfo(
                key: key,
                region: .china,
                name: name,
                successCount: studies.reduce(0) { $0 + ($1.billingSuccessMeasurements ?? 0) },
                totalDeposits: totalDeposits,
                unitPrice: unitPrice,
                periodSuccess: studies.reduce(0) { $0 + ($1.periodSuccessMeasurements ?? 0) },
                billingDate: billingDate,
                startDate: Calendar.current.date(byAdding: .day, value: -7, to: billingDate) ?? billingDate,
                endDate: billingDate,
                studies: studies
            )
        }

        model.orgs = [
            makeOrg(
                key: "lssd_01",
                name: "lssd_01",
                billingDate: now,
                studies: [
                    makeStudy(id: "A", name: "Study A", unitPrice: 0.8, billingSuccess: 1200, periodSuccess: 300),
                    makeStudy(id: "B", name: "Study B 5s", unitPrice: 0.8, billingSuccess: 400, periodSuccess: 120)
                ],
                totalDeposits: 500000,
                unitPrice: 0.8
            ),
            makeOrg(
                key: "lssd_02",
                name: "lssd_02",
                billingDate: now,
                studies: [
                    makeStudy(id: "C", name: "Study C", unitPrice: 0.8, billingSuccess: 800, periodSuccess: 200),
                    makeStudy(id: "D", name: "Study D 5s", unitPrice: 1.0, billingSuccess: 600, periodSuccess: 150)
                ],
                totalDeposits: 200000,
                unitPrice: 0.9
            ),
            makeOrg(
                key: "junying_01",
                name: "junying_01",
                billingDate: Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now,
                studies: [
                    makeStudy(id: "E", name: "Study E", unitPrice: 1.2, billingSuccess: 2000, periodSuccess: 500),
                    makeStudy(id: "F", name: "Study F 5s", unitPrice: 1.2, billingSuccess: 700, periodSuccess: 200)
                ],
                totalDeposits: 100000,
                unitPrice: 1.2
            )
        ]

        model.isPeriodNone = false
        model.billingPeriod = "2026.02.06 ~ 2026.02.12"

        return model
    }()

    return NavigationStack {
        StatisticsView(orgList: previewModel)
    }
}
