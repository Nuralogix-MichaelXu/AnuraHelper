import Foundation
import SwiftUI

struct OrgInfo: Identifiable {
    let id = UUID()
    let name: String
    let successCount: Int
    var totalDeposits: Double
    var unitPrice: Double
    let periodSuccess: Int
    let licenses: [LicenseResponse]
    let studies: [StudyResponse]
    let periodStudies: [StudyResponse]

    var licenseCount: Int {
        return licenses.count
    }
    var studyCount: Int {
        return studies.count
    }
    
    var balance: Double {
        return totalDeposits - totalCost
    }
    
    var totalDepositsString: String {
        return formatAmount(totalDeposits)
    }
    
    var totalCost: Double {
        return Double(successCount) * unitPrice
    }
    
    var periodCost: Double {
        return Double(periodSuccess) * unitPrice
    }
    
    var totalCostString: String {
        return formatAmount(totalCost)
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

    var periodCostString: String {
        return formatAmount(periodCost)
    }

    var unitPriceString: String {
        return formatUnitPrice(unitPrice)
    }
    
    var leftSuccessCount: Int {
        return max(Int(balance / unitPrice), 0)
    }
}

struct MeasurementInfo: Codable {
    let orgName: String
    let studyID: String
    let successCount: Int
    let failCount: Int
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
             return "生效中"
        case "EXPIRED":
            return "已过期"
        default:
            return "已失效"
        }
    }
    
    var DeviceRegistrationString: String {
        return "\(DeviceRegistrations)" + "/" + (MaxDevices == nil ? "无限使用" : "\(MaxDevices!)")
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
        
        if daysDifference < 0 {
            // 已过期
            return "已过期\(abs(daysDifference))天"
        } else if daysDifference > 0 {
            // 还未过期
            return "剩余\(daysDifference)天"
        } else {
            // 同一天
            return "剩余0天"
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
    var successMeasurements: Int?
    var failCount: Int?
    
    var statusString: String {
        switch StatusID {
        case "ACTIVE":
             return "有效"
        case "DELETED":
            return "已删除"
        default:
            return "已失效"
        }
    }
    
    var createdDateString: String {
        return TimeInterval(Created).toDateString()
    }
    
    var encryptedKey: String {
        return encryptUUID(ID)
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
