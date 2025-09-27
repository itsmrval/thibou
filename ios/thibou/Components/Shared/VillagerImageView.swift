import SwiftUI
import UIKit

struct VillagerImageView: View {
    let villagerId: String
    let imageType: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholder: Color
    let placeholderColor: Color?

    @State private var villagerImage: VillagerImage?

    init(
        villagerId: String,
        imageType: String = "full",
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 12,
        placeholder: Color = Color.gray.opacity(0.2),
        placeholderColor: Color? = nil
    ) {
        self.villagerId = villagerId
        self.imageType = imageType
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.placeholder = placeholder
        self.placeholderColor = placeholderColor
    }

    var body: some View {
        GenericImageView<VillagerImage>(
            imageData: villagerImage?.imageData,
            width: width,
            height: height,
            placeholderColor: placeholderColor
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            if villagerImage == nil {
                Task {
                    await loadVillagerImage()
                }
            }
        }
        .onChange(of: villagerId) { _, _ in
            villagerImage = nil
            Task {
                await loadVillagerImage()
            }
        }
    }

    private func loadVillagerImage() async {
        villagerImage = await VillagerService.shared.fetchVillagerImage(
            villagerId: villagerId,
            imageType: imageType
        )
    }
}