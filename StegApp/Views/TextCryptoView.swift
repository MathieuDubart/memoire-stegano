//
//  TextCryptoView.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import SwiftUI

import SwiftUI
import UIKit

struct TextCryptoView: View {
    
    // MARK: - UI types
    
    enum Mode: String, CaseIterable, Identifiable {
        case encrypt = "Chiffrer"
        case decrypt = "Déchiffrer"
        var id: String { rawValue }
    }
    
    enum OutputFormat: String, CaseIterable, Identifiable {
        case base64 = "Base64"
        case covertext = "Message"
        var id: String { rawValue }
    }
    
    // MARK: - Dependencies
    
    private let framePrefix = "STGFRAME1:"
    private let crypto = CryptoService()
    private let sessionKeys = SessionKeyStore()
    
    // MARK: - State
    
    @State private var mode: Mode = .encrypt
    @State private var outputFormat: OutputFormat = .covertext
    @State private var style: CoverStyle = .neutral
    
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMsg: String?
    @State private var showCopiedToast = false
    
    @State private var keyString: String = ""
    @State private var keyStatus: String = "Aucune clé active"
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    header
                    
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    keyCard
                    
                    card(title: "Format de sortie", subtitle: "Message sémantique + identifiant, ou frame brute") {
                        Picker("Format", selection: $outputFormat) {
                            ForEach(OutputFormat.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if outputFormat == .covertext {
                            Picker("Style", selection: $style) {
                                ForEach(CoverStyle.allCases) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .padding(.top, 4)
                            
                            Text("Le message reste “humain”. Le payload est transporté via un identifiant (id/ref) extractible par l’app.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Sortie: \(framePrefix)<base64> (copier/coller).")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    inputCard
                    
                    actionButtons
                    
                    if let errorMsg {
                        errorBanner(errorMsg)
                    }
                    
                    outputCard
                    
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("SteganoDemo")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if showCopiedToast {
                    toast("Copié dans le presse-papiers")
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .onAppear {
                refreshKeyStatus()
            }
        }
    }
    
    // MARK: - Sections
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Texte • Démo")
                .font(.title2).fontWeight(.semibold)
            Text("Clé séparée (export/import) + message sémantique + payload décodable.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
    
    private var keyCard: some View {
        card(
            title: "Clé (partage séparé)",
            subtitle: "Nécessaire pour déchiffrer. La clé n’est pas incluse dans le message."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                
                Text(keyStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                TextField("Clé Base32 (coller/importer ici)", text: $keyString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
                
                HStack(spacing: 10) {
                    Button {
                        generateKey()
                    } label: {
                        Label("Générer", systemImage: "key.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        copyKey()
                    } label: {
                        Label("Copier", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(keyString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button {
                        importKey()
                    } label: {
                        Label("Importer", systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(keyString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Text("Astuce démo : partage la clé une fois (ex. “code de session”), puis partage les messages (id:…).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var inputCard: some View {
        card(
            title: "Entrée",
            subtitle: mode == .encrypt
            ? "Texte clair à chiffrer"
            : "Colle un message généré par l’app (id/ref) ou une frame \(framePrefix)…"
        ) {
            TextEditor(text: $input)
                .frame(minHeight: 140)
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            
            HStack(spacing: 10) {
                Button {
                    input = UIPasteboard.general.string ?? input
                } label: {
                    Label("Coller", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                
                Button {
                    input = ""
                } label: {
                    Label("Vider", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
    }
    
    private var outputCard: some View {
        card(
            title: "Résultat",
            subtitle: mode == .encrypt ? "Message à partager" : "Texte clair"
        ) {
            TextEditor(text: $output)
                .frame(minHeight: 140)
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            
            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = output
                    toastCopied()
                } label: {
                    Label("Copier", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(output.isEmpty)
                
                Button {
                    output = ""
                } label: {
                    Label("Vider", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                run()
            } label: {
                Label(
                    mode == .encrypt ? "Chiffrer" : "Déchiffrer",
                    systemImage: mode == .encrypt ? "lock.fill" : "lock.open.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Button {
                let tmp = input
                input = output
                output = tmp
            } label: {
                Label("Swap", systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: 120)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(output.isEmpty && input.isEmpty)
        }
    }
    
    // MARK: - Logic
    
    private func run() {
        do {
            errorMsg = nil
            
            // Clé requise pour chiffrer/déchiffrer
            _ = try sessionKeys.loadKey()
            
            switch mode {
            case .encrypt:
                let frame = try crypto.encryptFrame(plaintext: input)
                
                switch outputFormat {
                case .base64:
                    output = framePrefix + frame.base64EncodedString()
                case .covertext:
                    output = CoverTextCodec.encode(frame: frame, style: style)
                }
                
            case .decrypt:
                let frameData = try decodeFrameData(from: input)
                output = try crypto.decryptFrame(frameData)
            }
            
        } catch {
            errorMsg = prettyError(error)
        }
    }
    
    private func decodeFrameData(from text: String) throws -> Data {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1) Frame base64 directe (tolère si le préfixe est au milieu d’un texte)
        if let range = trimmed.range(of: framePrefix) {
            let after = trimmed[range.upperBound...]
            let token = after.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
            if let data = Data(base64Encoded: token), FrameCodec.looksLikeFrame(data) {
                return data
            }
        }
        
        // 2) Message covertext (phrase + id/ref)
        if let data = try? CoverTextCodec.decode(coverText: trimmed),
           FrameCodec.looksLikeFrame(data) {
            return data
        }
        
        throw CryptoError.invalidInput
    }
    
    // MARK: - Key actions
    
    private func refreshKeyStatus() {
        do {
            _ = try sessionKeys.loadKey()
            let exported = try sessionKeys.exportKeyString()
            keyString = formatKeyForDisplay(exported)
            keyStatus = "Clé active disponible"
        } catch {
            keyStatus = "Aucune clé active (génère ou importe)"
        }
    }
    
    private func generateKey() {
        do {
            _ = try sessionKeys.generateAndSaveKey()
            let exported = try sessionKeys.exportKeyString()
            keyString = formatKeyForDisplay(exported)
            keyStatus = "Clé générée et enregistrée"
            UIPasteboard.general.string = normalizeKeyInput(keyString)
            toastCopied()
        } catch {
            errorMsg = prettyError(error)
        }
    }
    
    private func copyKey() {
        let normalized = normalizeKeyInput(keyString)
        guard !normalized.isEmpty else { return }
        UIPasteboard.general.string = normalized
        toastCopied()
    }
    
    private func importKey() {
        do {
            let normalized = normalizeKeyInput(keyString)
            try sessionKeys.importKeyString(normalized)
            keyString = formatKeyForDisplay(normalized)
            keyStatus = "Clé importée et enregistrée"
            toastCopied()
        } catch {
            errorMsg = prettyError(error)
        }
    }
    
    // MARK: - Helpers (UI)
    
    private func card(title: String, subtitle: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            content()
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
    
    private func toast(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(.quaternary, lineWidth: 1))
            .shadow(radius: 8)
    }
    
    private func toastCopied() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                showCopiedToast = false
            }
        }
    }
    
    // MARK: - Helpers (errors / formatting)
    
    private func prettyError(_ error: Error) -> String {
        if let cryptoError = error as? CryptoError {
            switch cryptoError {
            case .invalidInput:
                return "Entrée invalide. Colle une frame \(framePrefix)… ou un message généré par l’app (id/ref)."
            case .decryptionFailed:
                return "Déchiffrement impossible (mauvaise clé ou message corrompu)."
            }
        }
        
        if error is FrameError {
            return "Frame illisible (magic/version/format)."
        }
        
        if error is CoverCodecError {
            return "Message non décodable (id/ref manquant ou payload invalide)."
        }
        
        if error is SessionKeyError {
            return "Clé manquante ou invalide. Génère ou importe une clé avant de chiffrer/déchiffrer."
        }
        
        return "Erreur: \(String(describing: error))"
    }
    
    private func normalizeKeyInput(_ s: String) -> String {
        s.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatKeyForDisplay(_ s: String) -> String {
        let cleaned = normalizeKeyInput(s)
        guard !cleaned.isEmpty else { return "" }
        
        var out: [String] = []
        out.reserveCapacity((cleaned.count + 3) / 4)
        
        var i = cleaned.startIndex
        while i < cleaned.endIndex {
            let j = cleaned.index(i, offsetBy: 4, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            out.append(String(cleaned[i..<j]))
            i = j
        }
        
        // groups separated by spaces
        return out.joined(separator: " ")
    }
}
