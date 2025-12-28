//
//  Base32.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import Foundation


enum Base32Error: Error {
    case invalidCharacter
}
struct Base32 {
    static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    
    private static let decodeTable: [Character: UInt8] = {
        var dict: [Character: UInt8] = [:]
        for (i, c) in alphabet.enumerated() { dict[c] = UInt8(i) }
        return dict
    }()
    
    static func encode(_ data: Data) -> String {
        var output: [Character] = []
        output.reserveCapacity((data.count * 8 + 4) / 5)
        
        var buffer: UInt32 = 0
        var bitsLeft = 0
        
        for byte in data {
            buffer = (buffer << 8) | UInt32(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                let index = Int((buffer >> UInt32(bitsLeft - 5)) & 0x1F)
                output.append(alphabet[index])
                bitsLeft -= 5
            }
        }
        
        if bitsLeft > 0 {
            let index = Int((buffer << UInt32(5 - bitsLeft)) & 0x1F)
            output.append(alphabet[index])
        }
        
        return String(output)
    }
    
    static func decode(_ string: String) throws -> Data {
        let cleaned = string.uppercased().filter { !$0.isWhitespace && $0 != "-" && $0 != "_" }
        
        var buffer: UInt32 = 0
        var bitsLeft = 0
        var out = Data()
        out.reserveCapacity(cleaned.count * 5 / 8)
        
        for ch in cleaned {
            guard let val = decodeTable[ch] else { throw Base32Error.invalidCharacter }
            buffer = (buffer << 5) | UInt32(val)
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                let byte = UInt8((buffer >> UInt32(bitsLeft - 8)) & 0xFF)
                out.append(byte)
                bitsLeft -= 8
            }
        }
        
        return out
    }
}
