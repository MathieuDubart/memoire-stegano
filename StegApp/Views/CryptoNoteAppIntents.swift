import AppIntents
import Foundation

struct DecryptTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Decrypt Text"
    static var description = IntentDescription("Open CryptoNote and decrypt the provided text.")
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Text or URL")
    var content: String

    func perform() async throws -> some IntentResult {
        // Store the incoming content for the app to consume when it opens
        UserDefaults.standard.set(content, forKey: "IncomingText")
        UserDefaults.standard.set("decrypt", forKey: "IncomingMode")
        return .result()
    }
}

struct CryptoNoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DecryptTextIntent(),
            phrases: [
                "Decrypt with \(.applicationName)",
                "Decrypt in \(.applicationName)",
                "Open \(.applicationName) to decrypt",
                "Decrypt text using \(.applicationName)"
            ],
            shortTitle: "Decrypt Text",
            systemImageName: "lock.open"
        )
    }
}

