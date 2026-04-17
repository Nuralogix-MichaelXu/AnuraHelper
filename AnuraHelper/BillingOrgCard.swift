import SwiftUI

struct BillingOrgCard: View {
    let org: OrgInfo
    private struct Style {
        static let titleFont = Font.system(size: 14, weight: .bold)
        static let labelFont = Font.system(size: 11)
        static let labelColor = Color.text
        static let highlightColor = Color.lightBlue
        static let cardBackground = Color.lightPurple
        static let cardCornerRadius: CGFloat = 10
        static let cardShadow = Color.gray.opacity(0.5)
        static let cardShadowRadius: CGFloat = 5
        static let cardShadowX: CGFloat = 5
        static let cardShadowY: CGFloat = 5
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 15
        static let bottomMargin: CGFloat = 10
    }
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text(Localized("org_name_label") + ": ")
                        .font(Style.titleFont)
                        .foregroundColor(Style.labelColor)
                    Text(org.name)
                        .font(Style.titleFont)
                        .foregroundColor(Style.labelColor)
                }
                .padding(.bottom, Style.bottomMargin + 5)
                HStack(spacing: 0) {
                    Text(Localized("region_label") + ": \(org.region.name)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.labelColor)
                    Spacer()
                    Text(Localized("study_count_label") + ": \(org.studyCount)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.labelColor)
                    Spacer()
                    Text(Localized("success_count_label") + ": \(org.billingSuccessMeasurements)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.labelColor)
                }
                .padding(.bottom, Style.bottomMargin)
                HStack(spacing: 0) {
                    Text(Localized("total_deposits_label") + ": \(org.totalDepositsString)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.labelColor)
                    Spacer()
                    Text(Localized("unit_price_label") + ": \(org.unitPriceString)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.labelColor)
                }
                .padding(.bottom, Style.bottomMargin)
                HStack(spacing: 0) {
                    Text(Localized("billing_cost_label") + ": \(org.billingCostString)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.labelColor)
                    Spacer()
                    Text(Localized("balance_label") + ": ")
                        .font(Style.labelFont)
                        .foregroundColor(Style.labelColor)
                    Text("\(org.balanceString)")
                        .font(Style.labelFont)
                        .foregroundColor(org.balanceColor)
                }
                .padding(.bottom, Style.bottomMargin)
                HStack(spacing: 0) {
                    Text(Localized("period_success_label") + ": \(org.periodSuccessString)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.highlightColor)
                    Spacer()
                    Text(Localized("period_cost_label") + ": \(org.periodCostString)")
                        .font(Style.labelFont)
                        .foregroundColor(Style.highlightColor)
                }
            }
            .padding(.horizontal, Style.horizontalPadding)
            .padding(.vertical, Style.verticalPadding)
            .background(Style.cardBackground)
            .cornerRadius(Style.cardCornerRadius)
            .shadow(color: Style.cardShadow, radius: Style.cardShadowRadius, x: Style.cardShadowX, y: Style.cardShadowY)
            // 账单开始日期圆角文本
            Text(Localized("billing_date") + ": " + org.billingDate.yyyyMMddDateString)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.subText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.subBackgound)
                .cornerRadius(12)
                .padding([.top, .trailing], 2)
        }
    }
}
