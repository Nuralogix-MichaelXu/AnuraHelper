//
//  Common.swift
//  AnuraHelper
//
//  Created by Michael Xu on 2026/3/4.
//
import SwiftUI

extension TimeInterval {
    func toDateString() -> String {
        let date = Date(timeIntervalSince1970: self)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

extension Date {
    var yyyyMMddDateString: String {
        if LanguageManager.shared.isCNLanguage() {
            return dateFormatter("yyyy.MM.dd").string(from: self)
        }
        return dateFormatter("MM/dd/yyyy").string(from: self)
    }
    
    var yyyyMMddhhmmssDateString: String {
        return dateFormatter("yyyyMMddHHmmss").string(from: self)
    }
    
    var yyyyMMddhhmmssDateString2: String {
        return dateFormatter("yyyy-MM-dd HH:mm:ss").string(from: self)
    }
        
    func dateFormatter(_ dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter
    }

    // 自定义格式的 UTC 字符串
    func toUTCString(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
}

extension String {
    var dateFromYyyyMMddString: Date? {
        let formatter = DateFormatter()
        if LanguageManager.shared.isCNLanguage() {
            formatter.dateFormat = "yyyy.MM.dd"
        } else {
            formatter.dateFormat = "MM/dd/yyyy"
        }
        return formatter.date(from: self)
    }
}
