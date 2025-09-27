import SwiftUI

struct GenericImageView<ImageType>: View {
    let imageData: String?
    let width: CGFloat
    let height: CGFloat
    let placeholderColor: Color?

    var body: some View {
        Group {
            if let imageData = imageData,
               let uiImage = ImageManager.base64ToUIImage(imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: placeholderColor ?? .gray))
                    .scaleEffect(0.8)
            }
        }
        .frame(width: width, height: height)
    }

    init(imageData: String?, width: CGFloat, height: CGFloat, placeholderColor: Color? = nil) {
        self.imageData = imageData
        self.width = width
        self.height = height
        self.placeholderColor = placeholderColor
    }
}