import SwiftUI
import PhotosUI
import CoreML
import Vision

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var classification: String = ""
    @State private var showingImagePicker = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                } else {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .frame(height: 300)
                }
                
                Button("Select an image") {
                    showingImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Text(classification)
                    .font(.headline)
                    .padding()
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { _ in
                classifyImage()
            }
        }
        .colorScheme(.dark)
    }

    // MARK: - Image Classification Logic

    func classifyImage() {
        guard let image = selectedImage,
              let ciImage = CIImage(image: image) else {
            classification = "Not an image"
            return
        }

        do {
            // Load the ML model
            let model = try VNCoreMLModel(for: FastViTMA36F16().model)

            let request = VNCoreMLRequest(model: model) { request, error in
                if let results = request.results as? [VNClassificationObservation],
                   let topResult = results.first {
                    classification = "\(topResult.identifier) "
                } else {
                    classification = "Unexpected result type from model."
                }
            }

            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try handler.perform([request])

        } catch {
            classification = "Failed to process image: \(error.localizedDescription))"
        }
    }
}
