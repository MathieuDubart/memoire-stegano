//
//  Obfuscator.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import Foundation
import CryptoKit

struct Obfuscator {
    private static let salt = "SteganoDemo.Obf.v1"
    
    static func obfuscate(passphrase: String) -> Data {
        let plain = Data(passphrase.utf8)
        let mask = SHA256.hash(data: Data(salt.utf8))
        let maskBytes = Array(mask)
        
        var out = [UInt8](repeating: 0, count: plain.count)
        for i in 0..<plain.count {
            out[i] = plain[i] ^ maskBytes[i % maskBytes.count]
        }
        return Data(out)
    }
    
    static func deobfuscate(_ data: Data) -> String? {
        let mask = SHA256.hash(data: Data(salt.utf8))
        let maskBytes = Array(mask)
        
        var out = [UInt8](repeating: 0, count: data.count)
        for i in 0..<data.count {
            out[i] = data[i] ^ maskBytes[i % maskBytes.count]
        }
        return String(data: Data(out), encoding: .utf8)
    }
}
