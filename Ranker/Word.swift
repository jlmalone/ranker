
// ranker/Ranker/Word.swift

import Foundation

struct Word: Identifiable, Hashable {
    let id: Int64
    let name: String
    var rank: Double
    var isNotable: Bool = false
    var reviewed: Bool = false
    var eloScore: Double = 1200.0
}
