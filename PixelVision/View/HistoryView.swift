import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query private var historyItems: [ClassificationHistory]
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            List(historyItems.sorted(by: { $0.timestamp > $1.timestamp }), id: \.self) { item in
                HStack {
                    if let image = item.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 60, height: 60)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(item.result)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(Int(item.confidence * 100))%")
                            .foregroundColor(.secondary)
                        
                        // Static timestamp using formatted string
                        Text(item.formattedTimestamp)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .padding()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.black.opacity(0.1))
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("History")
        }
    }
}
