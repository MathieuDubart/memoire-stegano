//
//  CoverStyle.swift
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

import Foundation

enum CoverStyle: String, CaseIterable, Identifiable {
    case neutral = "Neutre"
    case poetic  = "Poétique"
    case tech    = "Tech"
    var id: String { rawValue }
}
