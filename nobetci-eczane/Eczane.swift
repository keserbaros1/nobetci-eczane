//
//  Eczane.swift
//  nobetci-eczane
//
//  Created by kesermac on 18.05.2025.
//

struct Eczane: Decodable {
    let name: String
    let dist: String
    let address: String
    let phone: String
    let loc: String
}

struct ApiResponse: Decodable {
    let success: Bool
    let result: [Eczane]
}
