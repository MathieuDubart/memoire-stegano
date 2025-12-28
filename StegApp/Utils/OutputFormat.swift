//
//  OutputFormat.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import SwiftUI


enum OutputFormat: String, CaseIterable, Identifiable {
    case base64 = "Base64"
    case covertext = "Covertext"
    var id: String { rawValue }
}


