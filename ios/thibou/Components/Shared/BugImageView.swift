import SwiftUI
import UIKit

struct BugImageView: View {
    let bugId: String
    let imageType: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholder: Color
    let placeholderColor: Color?

    @State private var bugImage: BugImage?

    init(
        bugId: String,
        imageType: String = "full",
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 12,
        placeholder: Color = Color.gray.opacity(0.2),
        placeholderColor: Color? = nil
    ) {
        self.bugId = bugId
        self.imageType = imageType
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.placeholder = placeholder
        self.placeholderColor = placeholderColor
    }

    var body: some View {
        GenericImageView<BugImage>(
            imageData: bugImage?.imageData,
            width: width,
            height: height,
            placeholderColor: placeholderColor
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            if bugImage == nil {
                Task {
                    await loadBugImage()
                }
            }
        }
        .onChange(of: bugId) { _, _ in
            bugImage = nil
            Task {
                await loadBugImage()
            }
        }
    }

    private func loadBugImage() async {
        bugImage = await BugService.shared.fetchBugImage(
            bugId: bugId,
            imageType: imageType
        )
    }

}