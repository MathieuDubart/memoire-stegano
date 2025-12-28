//
//  KeyMode.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

enum KeyMode: String, CaseIterable, Identifiable {
    case keychain = "Keychain"
    case obfuscation = "Obfuscation"
    var id: String { rawValue }
}
