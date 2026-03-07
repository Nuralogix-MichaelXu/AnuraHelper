import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: String
    private init() {
        if let lang = UserDefaults.standard.string(forKey: "AppLanguage") {
            currentLanguage = lang
        } else {
            currentLanguage = Locale.preferredLanguages.first?.contains("zh") == true ? "zh-Hans" : "en"
        }
    }
    func setLanguage(_ lang: String) {
        currentLanguage = lang
        UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
    }
    func localizedString(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    func isCNLanguage() -> Bool {
        return currentLanguage.contains("zh")
    }
}

struct LocalizedText: View {
    @ObservedObject private var langManager = LanguageManager.shared
    let key: String
    let font: Font?
    let color: Color?
    let weight: Font.Weight?
    let alignment: TextAlignment?
    
    init(_ key: String, font: Font? = nil, color: Color? = nil, weight: Font.Weight? = nil, alignment: TextAlignment? = nil) {
        self.key = key
        self.font = font
        self.color = color
        self.weight = weight
        self.alignment = alignment
    }
    var body: some View {
        Text(langManager.localizedString(key))
            .modifier(LocalizedTextModifier(font: font, color: color, weight: weight, alignment: alignment))
    }
}

private struct LocalizedTextModifier: ViewModifier {
    let font: Font?
    let color: Color?
    let weight: Font.Weight?
    let alignment: TextAlignment?
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .fontWeight(weight)
            .multilineTextAlignment(alignment ?? .leading)
    }
}

// 全局本地化字符串简写函数
func Localized(_ key: String) -> String {
    LanguageManager.shared.localizedString(key)
}

func AutoSize(_ cnSize: Double, _ enSize: Double) -> Double {
    return LanguageManager.shared.isCNLanguage() ? cnSize : enSize
}
