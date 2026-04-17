import Foundation
import SwiftUI

struct OrgInfo: Identifiable {
    let id = UUID()
    var key: String
    let region: Region
    let name: String
    let successCount: Int
    var totalDeposits: Double
    var unitPrice: Double
    let periodSuccess: Int?
    var billingDate: Date
    var startDate: Date
    var endDate: Date
    var studies: [StudyResponse]

    var studyCount: Int {
        return studies.count
    }
    
    var balance: Double {
        return totalDeposits - billingCost
    }
    
    var totalDepositsString: String {
        return formatAmount(totalDeposits)
    }
    
    var billingSuccessMeasurements: Int {
        return studies.reduce(0) {
            return $0 + ($1.billingSuccessMeasurements ?? $1.totalSuccessMeasurements ?? 0)
        }
    }
    
    var billingCost: Double {
        return studies.reduce(0) {
            return $0 + $1.billingCost
        }
    }

    var periodCost: Double? {
        if periodSuccess == nil {
            return nil
        }
        return studies.reduce(0) {
            return $0 + ($1.periodCost ?? 0)
        }
    }
    
    var periodCostString: String {
        return periodCost == nil ? "-" : formatAmount(periodCost!)
    }
    
    var periodSuccessString: String {
        return periodSuccess == nil ? "-" : "\(periodSuccess!)"
    }

    var billingCostString: String {
        return formatAmount(billingCost)
    }
    
    var balanceString: String {
        return formatAmount(balance)
    }
    
    var balanceColor: Color {
        if balance != 0 {
            return balance > 0 ? Color.greenText : Color.redText
        } else {
            return Color.text
        }
    }
    
    var unitPriceString: String {
        let prices = studies.compactMap { $0.unitPrice ?? unitPrice }
        let uniquePrices = Array(Set(prices)).sorted()
        if uniquePrices.count <= 1 {
            return formatUnitPrice(uniquePrices.first ?? unitPrice)
        }
        return uniquePrices.prefix(5).map { formatUnitPrice($0) }.joined(separator: "/")
    }
    
    var leftSuccessCount: Int {
        return max(Int(balance / unitPrice), 0)
    }
    
    mutating func resetStudyUnitPrice() {
        for i in studies.indices {
            studies[i].unitPrice = unitPrice
        }
    }
}

struct MeasurementInfo: Codable {
    let orgName: String
    let studyID: String
    let successCount: Int
}

// MARK: - LoginResponse Struct
struct LoginResponse: Codable {
    let Token: String
    let RefreshToken: String
}

struct LicenseResponse: Codable {
    let Created: UInt
    let StatusID: String
    let Expiration: String
    let MaxDevices: Int?
    let Key: String
    let DeviceRegistrations: Int
    let LicenseType: String
    var TotalCount: Int?
    
    var expirationString: String {
        return compareWithCurrentTime(Expiration)
    }
    
    var encryptedKey: String {
        return encryptUUID(Key)
    }
    
    var statusString: String {
        switch StatusID {
        case "ACTIVE":
             return Localized("license_status_active")
        case "EXPIRED":
            return Localized("license_status_expired")
        default:
            return Localized("license_status_invalid")
        }
    }
    var DeviceRegistrationString: String {
        return "\(DeviceRegistrations)/" + (MaxDevices == nil ? Localized("unlimited_usage") : "\(MaxDevices!)")
    }
    var createdDateString: String {
        return TimeInterval(Created).toDateString()
    }
    func compareWithCurrentTime(_ dateString: String) -> String {
        // 创建日期格式化器
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // 将字符串转换为Date对象
        guard let targetDate = formatter.date(from: dateString) else {
            return "/"
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        // 计算两个日期之间的天数差
        let components = calendar.dateComponents([.day], from: currentDate, to: targetDate)
        let daysDifference = components.day ?? 0
        
        if LanguageManager.shared.isCNLanguage() {
            if daysDifference < 0 {
                // 已过期
                return Localized("expired_days") + "\(abs(daysDifference))" + Localized("days_unit")
            } else if daysDifference > 0 {
                // 还未过期
                return Localized("remaining_days") + "\(daysDifference)" + Localized("days_unit")
            } else {
                // 同一天
                return Localized("remaining_days") + "0" + Localized("days_unit")
            }
        } else {
            if daysDifference < 0 {
                // 已过期
                return "\(abs(daysDifference))" + " " + Localized("days_unit") + " " + Localized("expired_days")
            } else if daysDifference > 0 {
                // 还未过期
                return "\(abs(daysDifference))" + " " + Localized("days_unit") + " " + Localized("remaining_days")
            } else {
                // 同一天
                return "0" + " " + Localized("days_unit") + " " + Localized("remaining_days")
            }
        }
    }
}

struct StudyResponse: Codable {
    let Created: UInt
    let ID: String
    let Name: String
    let Description: String
    let StatusID: String
    let Measurements: Int
    var TotalCount: Int?
    var totalSuccessMeasurements: Int?
    var periodSuccessMeasurements: Int?
    var billingSuccessMeasurements: Int?
    var periodBillingSuccessMeasurements: Int?
    var isPerioContainBilling: Bool?
    var unitPrice: Double?
    var periodCost: Double? {
        if periodSuccessMeasurements == nil {
            return nil
        }
        if let isPerioContainBilling = isPerioContainBilling, isPerioContainBilling {
            return (unitPrice ?? 0) * Double(billingSuccessMeasurements ?? 0)
        }
        let periodSuccessMeasurements = periodBillingSuccessMeasurements ?? periodSuccessMeasurements ?? totalSuccessMeasurements ?? 0
        return (unitPrice ?? 0) * Double(periodSuccessMeasurements)
    }
    
    var billingCost: Double {
        return (unitPrice ?? 0) * Double(billingSuccessMeasurements ?? totalSuccessMeasurements ?? 0)
    }

    var statusString: String {
        switch StatusID {
        case "ACTIVE":
             return Localized("study_status_active")
        case "DELETED":
            return Localized("study_status_deleted")
        default:
            return Localized("study_status_invalid")
        }
    }
        
    var createdDateString: String {
        return TimeInterval(Created).toDateString()
    }
    
    var encryptedKey: String {
        return encryptUUID(ID)
    }
    
    mutating func reset() {
        TotalCount = 0
        totalSuccessMeasurements = nil
        periodSuccessMeasurements = nil
        billingSuccessMeasurements = nil
        periodBillingSuccessMeasurements = nil
        isPerioContainBilling = nil
    }
}

struct MeasurementResponse: Codable {
    let StudyID: String
    let StatusID: String
    var TotalCount: Int?
}

nonisolated struct ErrorResponse: Codable {
    let Code: String
    let Message: String
}

func formatAmount(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.roundingMode = .halfUp
    formatter.groupingSeparator = ","
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

func formatUnitPrice(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 2
    formatter.roundingMode = .halfUp
    formatter.groupingSeparator = ","
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

func encryptUUID(_ key: String) -> String {
    guard key.count >= 8 else { return key }
    
    let prefix = String(key.prefix(4))
    let suffix = String(key.suffix(4))
    
    return "\(prefix)****\(suffix)"
}
