//
//  Amiibo.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 25/06/2025.
//


// Amiibo.swift
import Foundation

struct Amiibo: Codable, Identifiable, Hashable {
    let head: String
    let tail: String
    let name: String
    let amiiboSeries: String
    let gameSeries: String
    let type: String
    let character: String
    let image: String
    
    
    var id: String { "0x\(head)\(tail)" }

    enum CodingKeys: String, CodingKey {
        case head, tail, name, amiiboSeries, gameSeries, type, character, image
    }
}
struct AmiiboResponse: Codable {
    let amiibo: [Amiibo]
}

