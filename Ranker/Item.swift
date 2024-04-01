//
//  Item.swift
//  Ranker
//
//  Created by Joseph Malone on 4/2/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
