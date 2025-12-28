//
//  CoverTextCodec.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import Foundation
import Foundation

import Foundation

enum CoverCodecError: Error {
    case missingPayload
    case invalidPayload
}

struct CoverTextCodec {
    
    // MARK: - Base64URL helpers
    
    private static func b64urlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    private static func b64urlDecode(_ s: String) -> Data? {
        var b64 = s
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let pad = (4 - (b64.count % 4)) % 4
        if pad > 0 { b64.append(String(repeating: "=", count: pad)) }
        
        return Data(base64Encoded: b64)
    }
    
    // MARK: - Label par style (ce qui remplace ref:)
    
    private static func label(for style: CoverStyle) -> String {
        switch style {
        case .tech:
            return "ticket"   // alternatives possibles: "build", "case"
        case .neutral:
            return "code"     // alternatives: "id"
        case .poetic:
            return "note"     // alternatives: "vers"
        }
    }
    
    // MARK: - Phrase cover (sémantique)
    
    private static func coverSentence(style: CoverStyle) -> String {
        switch style {
        case .neutral:
            let templates = [
                "Petite mise au point: je reviens apres une verification rapide.",
                "Je note le point principal; je te confirme apres un dernier check.",
                "Rien d'urgent, mais je prefere etre precis avant de trancher.",
                "Je pense qu'on tient une bonne piste. Je te confirme bientot.",
                "Je fais une passe de verification et on avance."
            ]
            return templates.randomElement()!
            
        case .poetic:
            let templates = [
                "Je laisse passer la nuit, puis je reviens avec une reponse plus nette.",
                "Il suffit parfois d'un detail pour que tout se remette en place.",
                "Je garde la trace, et je reviens quand le sens devient plus clair.",
                "Je ne dis pas tout d'un coup; je laisse la phrase respirer.",
                "Un signe de plus, et tout s'emboite."
            ]
            return templates.randomElement()!
            
        case .tech:
            let templates = [
                "Je reproduis le bug, je patch, puis je te ping.",
                "Je viens de pousser un correctif; je verifie et je te confirme.",
                "J'ai isole le probleme. Je fais un test propre avant de merge.",
                "Ca passe en local. Je confirme apres une verif sur un autre device.",
                "Je garde un plan B au cas ou; validation finale juste apres."
            ]
            return templates.randomElement()!
        }
    }
    
    // MARK: - Public API
    
    /// Encode = phrase sémantique + (label: token)
    static func encode(frame: Data, style: CoverStyle) -> String {
        let token = b64urlEncode(frame)
        let sentence = coverSentence(style: style)
        let key = label(for: style)
        return "\(sentence) (\(key): \(token))"
    }
    
    /// Decode = récupère token via un motif stable (ticket|build|code|id|note|vers)
    static func decode(coverText: String) throws -> Data {
        let trimmed = coverText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Labels acceptés (tu peux ajuster)
        let pattern = #"(?:ticket|build|case|code|id|note|vers)\s*:\s*([A-Za-z0-9_-]+)"#
        
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        
        guard let match = regex.firstMatch(in: trimmed, options: [], range: range),
              match.numberOfRanges >= 2,
              let tokenRange = Range(match.range(at: 1), in: trimmed)
        else {
            throw CoverCodecError.missingPayload
        }
        
        let token = String(trimmed[tokenRange])
        guard let data = b64urlDecode(token) else { throw CoverCodecError.invalidPayload }
        return data
    }
}
