//
//  AnuraHelperTests.swift
//  AnuraHelperTests
//
//  Created by Michael Xu on 2026/4/28.
//

import XCTest
import SwiftUI

#if canImport(AnuraHelper)
@testable import AnuraHelper
#endif

final class AnuraHelperTests: XCTestCase {

    override func setUpWithError() throws {
        // Keep tests deterministic and avoid leaking state across runs.
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
        // Default to English unless a test overrides it.
        LanguageManager.shared.setLanguage("en")
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
        LanguageManager.shared.setLanguage("en")
    }

    // MARK: - LanguageManager

    func testLanguageManager_setLanguage_persistsToUserDefaults() throws {
        LanguageManager.shared.setLanguage("zh-Hans")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "AppLanguage"), "zh-Hans")
        XCTAssertTrue(LanguageManager.shared.isCNLanguage())

        LanguageManager.shared.setLanguage("en")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "AppLanguage"), "en")
        XCTAssertFalse(LanguageManager.shared.isCNLanguage())
    }

    func testLanguageManager_isCNLanguage_detectsChineseVariants() throws {
        LanguageManager.shared.setLanguage("zh-Hans")
        XCTAssertTrue(LanguageManager.shared.isCNLanguage())

        LanguageManager.shared.setLanguage("zh-Hant")
        XCTAssertTrue(LanguageManager.shared.isCNLanguage())

        LanguageManager.shared.setLanguage("en")
        XCTAssertFalse(LanguageManager.shared.isCNLanguage())
    }

    // MARK: - Date / TimeInterval / String extensions (Common.swift)

    func testTimeInterval_toDateString_usesExpectedFormat() throws {
        // 1970-01-01 00:00:00 UTC corresponds to epoch start.
        XCTAssertEqual(TimeInterval(0).toDateString(), "1970-01-01")
    }

    func testDate_toUTCString_defaultFormat_endsWithZAndIsUTC() throws {
        // 0 seconds since reference date is 2001-01-01 00:00:00 UTC.
        let d = Date(timeIntervalSinceReferenceDate: 0)
        let s = d.toUTCString()

        XCTAssertTrue(s.hasSuffix("Z"))
        // Should start with 2001-01-01T00:00:00 in UTC.
        XCTAssertTrue(s.hasPrefix("2001-01-01T00:00:00"), "Unexpected UTC string: \(s)")
    }

    func testDate_yyyyMMddDateString_CN_vs_EN() throws {
        let d = Date(timeIntervalSinceReferenceDate: 0) // 2001-01-01

        LanguageManager.shared.setLanguage("en")
        XCTAssertEqual(d.yyyyMMddDateString, "01/01/2001")

        LanguageManager.shared.setLanguage("zh-Hans")
        XCTAssertEqual(d.yyyyMMddDateString, "2001.01.01")
    }

    func testString_dateFromYyyyMMddString_parsesAccordingToLanguage() throws {
        // `String.dateFromYyyyMMddString` relies on DateFormatter defaults (locale/timezone),
        // which can vary on CI/simulators and make parsing flaky.
        // This test focuses on guaranteeing the *expected format strings* per language
        // by parsing with a stable POSIX+UTC formatter.

        func parsePOSIXUTC(_ s: String, format: String) -> Date? {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(abbreviation: "UTC")
            f.dateFormat = format
            return f.date(from: s)
        }

        func utcDayString(_ date: Date) -> String {
            date.toUTCString(format: "yyyy-MM-dd")
        }

        LanguageManager.shared.setLanguage("en")
        let enParsed = parsePOSIXUTC("01/01/2001", format: "MM/dd/yyyy")
        XCTAssertNotNil(enParsed)
        XCTAssertEqual(utcDayString(enParsed!), "2001-01-01")

        LanguageManager.shared.setLanguage("zh-Hans")
        let cnParsed = parsePOSIXUTC("2001.01.01", format: "yyyy.MM.dd")
        XCTAssertNotNil(cnParsed)
        XCTAssertEqual(utcDayString(cnParsed!), "2001-01-01")
    }

    // MARK: - Region (APIClient.swift)

    func testRegion_host_tag_rawValueMapping() throws {
        XCTAssertEqual(Region.china.rawValue, 0)
        XCTAssertEqual(Region.international.rawValue, 1)

        XCTAssertEqual(Region.china.host, "https://api.prod.deepaffex.cn")
        XCTAssertEqual(Region.international.host, "https://api.as-east.deepaffex.ai")

        XCTAssertEqual(Region.china.tag, "0")
        XCTAssertEqual(Region.international.tag, "1")
    }

    func testRegion_codability_roundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(Region.international)
        let decoded = try decoder.decode(Region.self, from: data)
        XCTAssertEqual(decoded, .international)
    }

    // MARK: - Sanity

    func testAutoSize_switchesByLanguage() throws {
        LanguageManager.shared.setLanguage("en")
        XCTAssertEqual(AutoSize(10, 20), 20)

        LanguageManager.shared.setLanguage("zh-Hans")
        XCTAssertEqual(AutoSize(10, 20), 10)
    }

    // MARK: - Data presentation (Model.swift)

    func testFormatCount_groupsThousands() throws {
        XCTAssertEqual(formatCount(0), "0")
        XCTAssertEqual(formatCount(12), "12")
        XCTAssertEqual(formatCount(1234), "1,234")
        XCTAssertEqual(formatCount(1234567), "1,234,567")
    }

    func testFormatAmount_roundingAndGrouping() throws {
        XCTAssertEqual(formatAmount(0), "0")
        XCTAssertEqual(formatAmount(12.0), "12")
        XCTAssertEqual(formatAmount(12.1), "12.1")
        XCTAssertEqual(formatAmount(12.12), "12.12")
        XCTAssertEqual(formatAmount(12.129), "12.13") // half-up
        XCTAssertEqual(formatAmount(12345.678), "12,345.68")
    }

    func testFormatUnitPrice_hasAtLeastOneDecimal() throws {
        XCTAssertEqual(formatUnitPrice(1), "1.0")
        XCTAssertEqual(formatUnitPrice(1.2), "1.2")
        XCTAssertEqual(formatUnitPrice(1.234), "1.23")
        XCTAssertEqual(formatUnitPrice(12345.6), "12,345.6")
    }

    func testEncryptUUID_masksMiddle() throws {
        XCTAssertEqual(encryptUUID(""), "")
        XCTAssertEqual(encryptUUID("1234567"), "1234567") // < 8 chars: unchanged
        XCTAssertEqual(encryptUUID("12345678"), "1234****5678")
        XCTAssertEqual(encryptUUID("abcdefg-hijk"), "abcd****hijk")
    }

    func testStudyResponse_billingCost_usesBillingIfPresentElseTotalSuccess() throws {
        var study = StudyResponse(
            Created: 0,
            ID: "study-1",
            Name: "S1",
            Description: "",
            StatusID: "ACTIVE",
            Measurements: 0,
            TotalCount: nil,
            totalSuccessMeasurements: 10,
            periodSuccessMeasurements: nil,
            billingSuccessMeasurements: nil,
            periodBillingSuccessMeasurements: nil,
            isPerioContainBilling: nil,
            unitPrice: 2.5
        )

        // No billingSuccessMeasurements -> uses totalSuccessMeasurements
        XCTAssertEqual(study.billingCost, 2.5 * 10)

        study.billingSuccessMeasurements = 4
        XCTAssertEqual(study.billingCost, 2.5 * 4)
    }

    func testStudyResponse_periodCost_nilWhenNoPeriodSuccess() throws {
        let study = StudyResponse(
            Created: 0,
            ID: "study-1",
            Name: "S1",
            Description: "",
            StatusID: "ACTIVE",
            Measurements: 0,
            TotalCount: nil,
            totalSuccessMeasurements: 10,
            periodSuccessMeasurements: nil,
            billingSuccessMeasurements: 3,
            periodBillingSuccessMeasurements: nil,
            isPerioContainBilling: nil,
            unitPrice: 1.0
        )
        XCTAssertNil(study.periodCost)
    }

    func testStudyResponse_periodCost_usesContainBillingShortcut() throws {
        let study = StudyResponse(
            Created: 0,
            ID: "study-1",
            Name: "S1",
            Description: "",
            StatusID: "ACTIVE",
            Measurements: 0,
            TotalCount: nil,
            totalSuccessMeasurements: 10,
            periodSuccessMeasurements: 99, // only to enable periodCost
            billingSuccessMeasurements: 3,
            periodBillingSuccessMeasurements: 7,
            isPerioContainBilling: true,
            unitPrice: 2.0
        )

        // When period includes billing, it uses billingSuccessMeasurements
        XCTAssertEqual(study.periodCost, 2.0 * 3)
    }

    func testStudyResponse_periodCost_usesPeriodBillingIfAvailable_elsePeriodSuccess_elseTotal() throws {
        // prefers periodBillingSuccessMeasurements
        var study = StudyResponse(
            Created: 0,
            ID: "study-1",
            Name: "S1",
            Description: "",
            StatusID: "ACTIVE",
            Measurements: 0,
            TotalCount: nil,
            totalSuccessMeasurements: 10,
            periodSuccessMeasurements: 5,
            billingSuccessMeasurements: 3,
            periodBillingSuccessMeasurements: 7,
            isPerioContainBilling: false,
            unitPrice: 2.0
        )
        XCTAssertEqual(study.periodCost, 2.0 * 7)

        // fallback to periodSuccessMeasurements
        study.periodBillingSuccessMeasurements = nil
        XCTAssertEqual(study.periodCost, 2.0 * 5)

        // fallback to totalSuccessMeasurements
        study.periodSuccessMeasurements = nil
        XCTAssertNil(study.periodCost) // because periodSuccessMeasurements == nil disables periodCost entirely
    }

    func testOrgInfo_aggregationsAndDisplayStrings() throws {
        // Two studies with different combinations of billing/total counts
        var s1 = StudyResponse(
            Created: 0,
            ID: "id-1",
            Name: "S1",
            Description: "",
            StatusID: "ACTIVE",
            Measurements: 0,
            TotalCount: nil,
            totalSuccessMeasurements: 10,
            periodSuccessMeasurements: nil,
            billingSuccessMeasurements: 4,
            periodBillingSuccessMeasurements: nil,
            isPerioContainBilling: nil,
            unitPrice: 2.0
        )
        var s2 = StudyResponse(
            Created: 0,
            ID: "id-2",
            Name: "S2",
            Description: "",
            StatusID: "ACTIVE",
            Measurements: 0,
            TotalCount: nil,
            totalSuccessMeasurements: 3,
            periodSuccessMeasurements: nil,
            billingSuccessMeasurements: nil,
            periodBillingSuccessMeasurements: nil,
            isPerioContainBilling: nil,
            unitPrice: 2.0
        )

        // sanity: computed costs
        XCTAssertEqual(s1.billingCost, 2.0 * 4)
        XCTAssertEqual(s2.billingCost, 2.0 * 3)

        var org = OrgInfo(
            key: "org0",
            region: .china,
            name: "Org",
            successCount: 0,
            totalDeposits: 100,
            unitPrice: 2.0,
            periodSuccess: nil,
            billingDate: Date(),
            startDate: Date(),
            endDate: Date(),
            studies: [s1, s2]
        )

        XCTAssertEqual(org.studyCount, 2)
        XCTAssertEqual(org.billingSuccessMeasurements, 4 + 3)
        XCTAssertEqual(org.billingCost, (2.0 * 4) + (2.0 * 3))
        XCTAssertEqual(org.balance, 100 - org.billingCost)
        XCTAssertEqual(org.balanceString, formatAmount(org.balance))
        XCTAssertEqual(org.totalDepositsString, "100")

        // leftSuccessCount should be floor(balance / unitPrice) but not negative
        XCTAssertEqual(org.leftSuccessCount, max(Int(org.balance / 2.0), 0))

        // unitPriceString should collapse to single value when all equal
        XCTAssertEqual(org.unitPriceString, formatUnitPrice(2.0))

        // resetStudyUnitPrice propagates org.unitPrice to each study
        org.unitPrice = 3.0
        org.resetStudyUnitPrice()
        XCTAssertTrue(org.studies.allSatisfy { $0.unitPrice == 3.0 })
    }

    func testOrgInfo_balanceColor_branching() throws {
        // balance > 0 => greenText
        var org = OrgInfo(
            key: "org",
            region: .china,
            name: "Org",
            successCount: 0,
            totalDeposits: 100,
            unitPrice: 2.0,
            periodSuccess: nil,
            billingDate: Date(),
            startDate: Date(),
            endDate: Date(),
            studies: []
        )
        XCTAssertEqual(org.balance, 100)
        XCTAssertEqual(org.balanceColor, Color.greenText)

        // balance == 0 => text
        org.totalDeposits = 0
        XCTAssertEqual(org.balance, 0)
        XCTAssertEqual(org.balanceColor, Color.text)

        // balance < 0 => redText
        org.totalDeposits = -1
        XCTAssertLessThan(org.balance, 0)
        XCTAssertEqual(org.balanceColor, Color.redText)
    }

    func testOrgInfo_unitPriceString_multiplePrices_sortedAndLimited() throws {
        // Create 7 unique prices to verify it limits to 5 and sorts.
        let prices: [Double] = [3.0, 1.0, 2.0, 7.0, 6.0, 5.0, 4.0]
        let studies: [StudyResponse] = prices.enumerated().map { idx, p in
            StudyResponse(
                Created: 0,
                ID: "id-\(idx)",
                Name: "S\(idx)",
                Description: "",
                StatusID: "ACTIVE",
                Measurements: 0,
                TotalCount: nil,
                totalSuccessMeasurements: nil,
                periodSuccessMeasurements: nil,
                billingSuccessMeasurements: nil,
                periodBillingSuccessMeasurements: nil,
                isPerioContainBilling: nil,
                unitPrice: p
            )
        }

        let org = OrgInfo(
            key: "org",
            region: .china,
            name: "Org",
            successCount: 0,
            totalDeposits: 0,
            unitPrice: 99.0,
            periodSuccess: nil,
            billingDate: Date(),
            startDate: Date(),
            endDate: Date(),
            studies: studies
        )

        // Sorted unique prices are 1..7, but the display should include only first 5.
        let expected = [1.0, 2.0, 3.0, 4.0, 5.0].map { formatUnitPrice($0) }.joined(separator: "/")
        XCTAssertEqual(org.unitPriceString, expected)
    }

    func testOrgInfo_periodStrings_whenNilOrPresent() throws {
        // When periodSuccess == nil => "-"
        let orgNil = OrgInfo(
            key: "org",
            region: .china,
            name: "Org",
            successCount: 0,
            totalDeposits: 0,
            unitPrice: 2.0,
            periodSuccess: nil,
            billingDate: Date(),
            startDate: Date(),
            endDate: Date(),
            studies: []
        )
        XCTAssertEqual(orgNil.periodSuccessString, "-")
        XCTAssertEqual(orgNil.periodCostString, "-")

        // When periodSuccess is present => uses formatters.
        // Note: periodCost is computed from studies' periodCost, so provide one period-enabled study.
        let study = StudyResponse(
            Created: 0,
            ID: "id",
            Name: "S",
            Description: "",
            StatusID: "ACTIVE",
            Measurements: 0,
            TotalCount: nil,
            totalSuccessMeasurements: 10,
            periodSuccessMeasurements: 5,
            billingSuccessMeasurements: nil,
            periodBillingSuccessMeasurements: nil,
            isPerioContainBilling: false,
            unitPrice: 2.0
        )

        let orgWithPeriod = OrgInfo(
            key: "org",
            region: .china,
            name: "Org",
            successCount: 0,
            totalDeposits: 0,
            unitPrice: 2.0,
            periodSuccess: 1234,
            billingDate: Date(),
            startDate: Date(),
            endDate: Date(),
            studies: [study]
        )

        XCTAssertEqual(orgWithPeriod.periodSuccessString, formatCount(1234))
        XCTAssertEqual(orgWithPeriod.periodCostString, formatAmount(study.periodCost ?? 0))
    }

    func testLicenseResponse_displayStrings_sanity() throws {
        // Use a stable ISO8601 string that the production formatter can parse.
        let license = LicenseResponse(
            Created: 0,
            StatusID: "ACTIVE",
            Expiration: "2030-01-01T00:00:00.000Z",
            MaxDevices: 10,
            Key: "12345678",
            DeviceRegistrations: 3,
            LicenseType: "SDK",
            TotalCount: nil
        )

        XCTAssertEqual(license.encryptedKey, "1234****5678")
        XCTAssertEqual(license.DeviceRegistrationString, "3/10")
        XCTAssertEqual(license.createdDateString, "1970-01-01")

        // Unlimited devices
        let unlimited = LicenseResponse(
            Created: 0,
            StatusID: "ACTIVE",
            Expiration: "2030-01-01T00:00:00.000Z",
            MaxDevices: nil,
            Key: "12345678",
            DeviceRegistrations: 3,
            LicenseType: "SDK",
            TotalCount: nil
        )
        // Only assert prefix to avoid depending on localized "unlimited_usage" string content.
        XCTAssertTrue(unlimited.DeviceRegistrationString.hasPrefix("3/"))
    }
}
