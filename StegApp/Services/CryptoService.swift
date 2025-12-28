//
//  Untitled.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

// CryptoService.swift

import Foundation
import CryptoKit
import Security
import Foundation
import CryptoKit
import Security

// MARK: - Errors

enum CryptoError: Error {
    case invalidInput
    case decryptionFailed
}

enum KeyGenError: Error {
    case randomFailed(OSStatus)
}
final class CryptoService {
    private let keyStore = SessionKeyStore()
    
    func encryptFrame(plaintext: String) throws -> Data {
        let key = try keyStore.loadKey()
        let sealed = try ChaChaPoly.seal(Data(plaintext.utf8), using: key)
        let combined = sealed.combined
        return FrameCodec.packV2(cipherCombined: combined)
    }
    
    func decryptFrame(_ frame: Data) throws -> String {
        let combined = try FrameCodec.unpackV2(frame)
        let key = try keyStore.loadKey()
        
        let box = try ChaChaPoly.SealedBox(combined: combined)
        let clear = try ChaChaPoly.open(box, using: key)
        
        guard let text = String(data: clear, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        return text
    }
}
