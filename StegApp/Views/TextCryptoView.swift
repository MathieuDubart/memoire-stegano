import SwiftUI
import UIKit

struct TextCryptoView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case encrypt = "ENCRYPT"
        case decrypt = "DECRYPT"
        var id: String { rawValue }
    }
    
    enum LocalCoverStyle: String, CaseIterable, Identifiable {
        case neutral = "neutral"
        case poetic = "poetic"
        case tech = "tech"
        var id: String { rawValue }
    }
    
    @State private var mode: Mode = .encrypt
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var showError: Bool = false
    @State private var errorText: String = ""
    @State private var style: LocalCoverStyle = .tech
    @FocusState private var inputFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    
    private let crypto = CryptoService()
    
    private func toGlobalCoverStyle(_ local: LocalCoverStyle) -> CoverStyle {
        switch local {
        case .neutral: return .neutral
        case .poetic: return .poetic
        case .tech: return .tech
        }
    }
    
    // Couleur dynamique
    private var accentColor: Color {
        mode == .encrypt ? .blue : .orange
    }
    
    var body: some View {
        TabView {
            mainContent
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
        }
        .tint(accentColor)
    }
    
    private var mainContent: some View {
        VStack(spacing: 28) {
            // En-tête
            VStack(spacing: 14) {
                Text("CryptoNote")
                    .font(.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Zone d'entrée
            HStack {
                Spacer()
                Button(action: pasteInput) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                            .font(.caption).bold()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.12))
                    )
                    .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 2)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                
                TextEditor(text: $input)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .opacity(input.isEmpty ? 0.85 : 1)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($inputFocused)
                    .onChange(of: input) { oldValue, newValue in
                        // If the user presses return at the end, remove it and dismiss keyboard
                        if newValue.hasSuffix("\n") {
                            input = String(newValue.dropLast())
                            inputFocused = false
                        }
                    }
                
                if input.isEmpty {
                    Text(mode == .encrypt
                        ? "Enter your message here... (Key will be embedded)"
                        : "Paste encrypted message...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 2)
            
            // Picker style uniquement si encrypt
            if mode == .encrypt {
                Picker("Cover Style", selection: $style) {
                    ForEach(LocalCoverStyle.allCases) { s in
                        Text(s.rawValue.capitalized).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 2)
            }
            
            // Bouton d'action principal
            Button(action: mainButtonAction) {
                HStack {
                    Image(systemName: mode == .encrypt ? "lock.fill" : "lock.open.fill")
                    Text(mode == .encrypt ? "Encrypt Message" : "Decrypt Message")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(accentColor)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 2)
            
            // Zone de résultat
            HStack {
                Spacer()
                Button(action: copyOutput) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                            .font(.caption).bold()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.12))
                    )
                    .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
                .disabled(output.isEmpty)
                .opacity(output.isEmpty ? 0.3 : 1)
            }
            .padding(.trailing, 2)
            
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                
                ScrollView {
                    Text(output.isEmpty
                         ? (mode == .encrypt
                            ? "9d+3JdYkLm... (encrypted message example)"
                            : "This is your decrypted message.")
                         : output)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 2)
            
            // Affichage d'erreur si besoin
            if showError {
                Text(errorText)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 26)
        .background(Color(.systemBackground).ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { inputFocused = false }
        .onAppear {
            inputFocused = true
            handleIncomingFromShortcuts()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                handleIncomingFromShortcuts()
            }
        }
    }
    
    private func mainButtonAction() {
        showError = false
        errorText = ""
        output = ""
        
        do {
            switch mode {
            case .encrypt:
                let encryptedFrame = try crypto.encryptFrame(plaintext: input)
                let coverText = CoverTextCodec.encode(frame: encryptedFrame, style: toGlobalCoverStyle(style))
                output = coverText
            case .decrypt:
                let frame = try CoverTextCodec.decode(coverText: input)
                let decrypted = try crypto.decryptFrame(frame)
                output = decrypted
            }
        } catch {
            errorText = prettyError(error)
            showError = true
        }
    }
    
    private func copyOutput() {
        guard !output.isEmpty else { return }
        UIPasteboard.general.string = output
    }
    
    private func pasteInput() {
        if let str = UIPasteboard.general.string {
            input = str
            inputFocused = true
        }
    }
    
    private func handleIncomingFromShortcuts() {
        let defaults = UserDefaults.standard
        guard let incoming = defaults.string(forKey: "IncomingText") else { return }
        // Clear so we don't handle it again
        defaults.removeObject(forKey: "IncomingText")
        defaults.removeObject(forKey: "IncomingMode")
        // Apply to UI and auto-decrypt
        mode = .decrypt
        input = incoming
        mainButtonAction()
    }
    
    private func prettyError(_ error: Error) -> String {
        // You can customize this as needed. Here's a simple example:
        // If the error conforms to LocalizedError, use its description, else fallback.
        if let localError = error as? LocalizedError {
            if let description = localError.errorDescription {
                return description
            }
        }
        return error.localizedDescription
    }
}

#Preview {
    TextCryptoView()
}
