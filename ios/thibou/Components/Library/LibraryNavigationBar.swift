import SwiftUI
import UIKit

struct LibraryNavigationBar: View {
    @Binding var selectedCategory: LibraryCategory
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?

    @Namespace private var highlightNamespace
    @StateObject private var localizationManager = LocalizationManager.shared

    private var categories: [LibraryCategory] { LibraryCategory.allCases }

    var body: some View {
        HStack(spacing: 2) {
            NavigationArrow(
                direction: .left,
                action: onPrevious,
                isDisabled: !canGoPrevious()
            )

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: category == selectedCategory,
                                highlightNamespace: highlightNamespace
                            ) {
                                changeSelection(to: category)
                            }
                            .id(category)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                }
                .onChange(of: selectedCategory) { _, newCategory in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newCategory, anchor: .center)
                    }
                }
            }

            NavigationArrow(
                direction: .right,
                action: onNext,
                isDisabled: !canGoNext()
            )
        }
        .padding(4)
    }

    private func changeSelection(to category: LibraryCategory) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func canGoPrevious() -> Bool {
        guard let currentIndex = categories.firstIndex(of: selectedCategory) else { return false }
        return currentIndex > 0
    }

    private func canGoNext() -> Bool {
        guard let currentIndex = categories.firstIndex(of: selectedCategory) else { return false }
        return currentIndex < categories.count - 1
    }
}

private struct CategoryChip: View {
    let category: LibraryCategory
    let isSelected: Bool
    let highlightNamespace: Namespace.ID
    let onTap: () -> Void

    private var corner: CGFloat { 12 }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ThibouTheme.Colors.skyBlue.opacity(0.30),
                                    ThibouTheme.Colors.lavender.opacity(0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .matchedGeometryEffect(id: "chip_highlight", in: highlightNamespace)
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .stroke(ThibouTheme.Colors.skyBlue.opacity(0.45), lineWidth: 1)
                        )
                }

                HStack(spacing: 6) {
                    icon(for: category)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 16, height: 16)

                    Text(category.localizedName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .compositingGroup()
            }
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .accessibilityLabel(Text(category.localizedName))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isSelected)
    }

    private func icon(for category: LibraryCategory) -> Image {
        if let ui = UIImage(named: category.customImage) {
            return Image(uiImage: ui)
        } else {
            return Image(systemName: fallbackSystemIconName(for: category))
        }
    }

    private func fallbackSystemIconName(for category: LibraryCategory) -> String {
        switch category {
        case .villageois: return "person.2.fill"
        case .poissons:   return "fish"
        case .insectes:   return "ant.fill"
        case .fossiles:   return "leaf.fill"
        case .vetements:  return "tshirt.fill"
        case .objets:     return "shippingbox.fill"
        }
    }
}

private enum ArrowDirection {
    case left, right

    var systemImage: String {
        switch self {
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }
}

private struct NavigationArrow: View {
    let direction: ArrowDirection
    let action: (() -> Void)?
    let isDisabled: Bool

    var body: some View {
        Button(action: {
            action?()
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }) {
            Image(systemName: direction.systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary.opacity(isDisabled ? 0.3 : 0.6))
                .frame(width: 24, height: 24)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || action == nil)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}
