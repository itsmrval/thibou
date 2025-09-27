import SwiftUI

struct LibraryView: View {
    @Binding var selectedCategory: LibraryCategory

    var body: some View {
        LibraryTabView(selectedCategory: $selectedCategory)
            .navigationTitle("Librairie")
            .navigationBarTitleDisplayMode(.automatic)
    }
}
