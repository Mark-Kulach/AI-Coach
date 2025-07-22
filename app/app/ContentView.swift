import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var videoURLs: [URL] = []

    var body: some View {
        VStack(spacing: 20) {
            PhotosPicker("Select Videos", selection: $selectedItems, matching: .videos, photoLibrary: .shared())
                .padding()

            if !videoURLs.isEmpty {
                Button("Upload All") {
                    for url in videoURLs {
                        upload(url)
                    }
                }
            }
        }
        .onChange(of: selectedItems) {
            Task {
                videoURLs.removeAll()
                for item in selectedItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let filename = UUID().uuidString + ".mov"
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                        try? data.write(to: tempURL)
                        videoURLs.append(tempURL)
                    }
                }
            }
        }
    }

    func upload(_ fileURL: URL) {
        let filename = UUID().uuidString + ".mov"
        let mimeType = "video/quicktime"

        // 1. Get pre-signed URL from FastAPI
        var request = URLRequest(url: URL(string: "http://localhost:8000/generate-upload-url")!) // Replace with your server URL
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: String] = [
            "filename": filename,
            "content_type": mimeType
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: json)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                let result = try? JSONDecoder().decode([String: String].self, from: data),
                let presignedURL = result["url"],
                let uploadURL = URL(string: presignedURL)
            else {
                print("Failed to get upload URL")
                return
            }

            // 2. Upload video directly to S3
            var uploadRequest = URLRequest(url: uploadURL)
            uploadRequest.httpMethod = "PUT"
            uploadRequest.setValue(mimeType, forHTTPHeaderField: "Content-Type")

            let videoData = try? Data(contentsOf: fileURL)

            URLSession.shared.uploadTask(with: uploadRequest, from: videoData) { _, res, err in
                if let err = err {
                    print("Upload failed: \(err)")
                } else {
                    print("Upload succeeded to: \(uploadURL)")
                }
            }.resume()

        }.resume()
    }
}
