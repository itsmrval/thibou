import SwiftUI
import UIKit

struct FishImageView: View {
    let fishId: String
    let imageType: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholder: Color
    let placeholderColor: Color?

    @State private var fishImage: FishImage?

    init(
        fishId: String,
        imageType: String = "full",
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 12,
        placeholder: Color = Color.gray.opacity(0.2),
        placeholderColor: Color? = nil
    ) {
        self.fishId = fishId
        self.imageType = imageType
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.placeholder = placeholder
        self.placeholderColor = placeholderColor
    }

    var body: some View {
        GenericImageView<FishImage>(
            imageData: fishImage?.imageData,
            width: width,
            height: height,
            placeholderColor: placeholderColor
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            if fishImage == nil {
                Task {
                    await loadFishImage()
                }
            }
        }
        .onChange(of: fishId) { _, _ in
            fishImage = nil
            Task {
                await loadFishImage()
            }
        }
    }

    private func loadFishImage() async {
        fishImage = await FishService.shared.fetchFishImage(
            fishId: fishId,
            imageType: imageType
        )
    }

}