import SwiftUI
import Combine

class AlertManager: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var buttonText: String = ""
    var onDismiss: (() -> Void)? = nil
    
    func showAlert(title: String, message: String, buttonText: String = Localized("confirm"), onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.buttonText = buttonText
        self.onDismiss = onDismiss
        self.isPresented = true
    }
}
