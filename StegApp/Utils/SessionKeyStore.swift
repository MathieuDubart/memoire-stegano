//
//  SessionKeyStore.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import Foundation
import CryptoKit
import Security

enum SessionKeyError: Error {
    case missingKey
    case invalidKeyString
    case keychainError(OSStatus)
}

struct SessionKeyStore {
    private let service = "SteganoDemo.SessionKey"
    private let account = "active"
    
    func loadKey() throws -> SymmetricKey {
        guard let data = try loadKeyData() else { throw SessionKeyError.missingKey }
        return SymmetricKey(data: data)
    }
    
    func saveKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        try saveKeyData(data)
    }
    
    func generateAndSaveKey() throws -> SymmetricKey {
        var bytes = [UInt8](repeating: 0, count: 32) // 256-bit
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw SessionKeyError.keychainError(status) }
        
        let key = SymmetricKey(data: Data(bytes))
        try saveKey(key)
        return key
    }
    
    // MARK: - Export / Import (format humain)
    
    /// Export en Base32 (lisible, sans symbols +/=/)
    func exportKeyString() throws -> String {
        let key = try loadKey()
        let data = key.withUnsafeBytes { Data($0) }
        return Base32.encode(data)
    }
    
    /// Import depuis Base32
    func importKeyString(_ s: String) throws {
        let cleaned = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = try? Base32.decode(cleaned), data.count == 32 else {
            throw SessionKeyError.invalidKeyString
        }
        try saveKey(SymmetricKey(data: data))
    }
    
    // MARK: - Keychain plumbing
    
    private func loadKeyData() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SessionKeyError.keychainError(status) }
        
        return item as? Data
    }
    
    private func saveKeyData(_ data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query.merging(attrs) { _, new in new } as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let upd = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
            guard upd == errSecSuccess else { throw SessionKeyError.keychainError(upd) }
            return
        }
        
        guard status == errSecSuccess else { throw SessionKeyError.keychainError(status) }
    }
    
    func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // OK si supprimé ou déjà absent
        if status == errSecSuccess || status == errSecItemNotFound {
            return
        }
        
        throw SessionKeyError.keychainError(status)
    }
}
