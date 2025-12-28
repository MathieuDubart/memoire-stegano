//
//  FrameCodec.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import Foundation

enum FrameError: Error {
    case invalidMagic
    case invalidVersion
    case invalidFormat
}
struct FrameCodec {
    private static let magic: [UInt8] = [0x53, 0x47, 0x46, 0x31] // "SGF1"
    private static let version: UInt8 = 2
    
    static func packV2(cipherCombined: Data) -> Data {
        var data = Data()
        data.append(contentsOf: magic)
        data.append(version)
        
        var cLen = UInt32(cipherCombined.count).bigEndian
        data.append(Data(bytes: &cLen, count: 4))
        data.append(cipherCombined)
        
        return data
    }
    
    static func unpackV2(_ data: Data) throws -> Data {
        var i = 0
        func read(_ n: Int) throws -> Data {
            guard i + n <= data.count else { throw FrameError.invalidFormat }
            let out = data.subdata(in: i..<(i + n))
            i += n
            return out
        }
        
        let m = [UInt8](try read(4))
        guard m == magic else { throw FrameError.invalidMagic }
        
        let v = [UInt8](try read(1))[0]
        guard v == version else { throw FrameError.invalidVersion }
        
        let cLenData = try read(4)
        let cLen = cLenData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        let cipher = try read(Int(cLen))
        return cipher
    }
    
    static func looksLikeFrame(_ data: Data) -> Bool {
        guard data.count >= 5 else { return false }
        return data[0] == 0x53 && data[1] == 0x47 && data[2] == 0x46 && data[3] == 0x31 && data[4] == version
    }
}
