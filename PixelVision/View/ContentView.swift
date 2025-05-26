import SwiftUI
import PhotosUI
import CoreML
import Vision
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            AnalyzerView()
                .tabItem {
                    Label("Analyze", systemImage: "photo.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "book.pages")
                }
        }
        .colorScheme(.dark)
    }
}

// MARK: - Analyzer View

struct AnalyzerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var classification: String = "Ready to identify"
    @State private var isAnalyzing = false
    
    // To save history
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Image Display
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    } else {
                        Image(systemName: "photo.stack.fill")
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 100))
                            .foregroundColor(.white)
                    }
                    
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(24)
                            .background(.thinMaterial)
                            .cornerRadius(20)
                    }
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                
                // Classification Result
                VStack(spacing: 8) {
                    Text(classification)
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .animation(.easeInOut, value: classification)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Select an image")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isAnalyzing)
                    
                    if selectedImage != nil {
                        Button(role: .destructive) {
                            selectedItem = nil
                            selectedImage = nil
                            classification = "Ready to identify"
                        } label: {
                            Label("Clear", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
            }
            .padding()
            .navigationTitle("Image Analyzer")
        }
        .onChange(of: selectedItem) { _ in
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    classifyImage()
                }
            }
        }
    }
    
    func classifyImage() {
        guard let image = selectedImage,
              let ciImage = CIImage(image: image) else {
            classification = "Failed to load image"
            return
        }
        
        isAnalyzing = true
        classification = "Analyzing..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let config = MLModelConfiguration()
                let model = try VNCoreMLModel(for: FastViTMA36F16(configuration: config).model)
                
                let request = VNCoreMLRequest(model: model) { request, error in
                    DispatchQueue.main.async {
                        isAnalyzing = false
                        
                        if let error = error {
                            classification = "Error: \(error.localizedDescription)"
                            return
                        }
                        
                        if let results = request.results as? [VNClassificationObservation],
                           let topResult = results.first {
                            let resultText = "\(topResult.identifier) (\(String(format: "%.1f", topResult.confidence * 100))%)"
                            classification = resultText
                            
                            // Save to history
                            let historyItem = ClassificationHistory(
                                result: topResult.identifier,
                                confidence: Double(topResult.confidence),
                                image: image
                            )
                            modelContext.insert(historyItem)
                        } else {
                            classification = "Unexpected result"
                        }
                    }
                }
                
                let handler = VNImageRequestHandler(ciImage: ciImage)
                try handler.perform([request])
                
            } catch {
                DispatchQueue.main.async {
                    isAnalyzing = false
                    classification = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
