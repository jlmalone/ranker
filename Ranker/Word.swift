
import Foundation

struct Word: Identifiable {
    let id = UUID()  // Unique identifier
    let name: String
    var rank: Double  // Between 0 (low) and 1 (high)
    var isNotable: Bool = false  // Flag for marking important words
    var reviewed: Bool = false //
}
