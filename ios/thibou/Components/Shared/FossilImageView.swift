import SwiftUI

struct FossilImageView: View {
    let fossilId: String
    let partName: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholderColor: Color

    @State private var image: FossilImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image, let uiImage = decodeBase64Image(image.image_data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else if isLoading {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(placeholderColor.opacity(0.2))
                    .frame(width: width, height: height)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: placeholderColor))
                            .scaleEffect(0.6)
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(placeholderColor.opacity(0.2))
                    .frame(width: width, height: height)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(placeholderColor.opacity(0.5))
                            .font(.system(size: min(width, height) * 0.4))
                    )
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoading = true
        let fetchedImage = await FossilService.shared.fetchFossilImage(fossilId: fossilId, partName: partName)
        image = fetchedImage
        isLoading = false
    }

    private func decodeBase64Image(_ base64String: String) -> UIImage? {
        let base64Data = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
        guard let imageData = Data(base64Encoded: base64Data) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}
