import Foundation
import SwiftData
import SwiftUI

@Model
final class ClassificationHistory {
    var timestamp: Date
    var result: String
    var confidence: Double
    var imageData: Data?

    init(timestamp: Date = Date(), result: String, confidence: Double, image: UIImage? = nil) {
        self.timestamp = timestamp
        self.result = result
        self.confidence = confidence
        self.imageData = image?.jpegData(compressionQuality: 1.0)
    }

    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }

    // MARK: - Formatted Timestamp (Static)

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        
        // Use relative formatting for recent dates
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
