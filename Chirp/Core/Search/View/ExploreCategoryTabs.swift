//
//  ExploreCategoryTabs.swift
//  Chirp
//
//  Created by Juan Palacio on 10.12.2025.
//

import SwiftUI

struct ExploreCategoryTabs: View {
    @Binding var selectedCategory: ExploreCategory
    @Namespace private var animation

    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ExploreCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        animation: animation
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    var animation: Namespace.ID

    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Underline indicator
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 3)

                if isSelected {
                    Rectangle()
                        .fill(twitterBlue)
                        .frame(height: 3)
                        .matchedGeometryEffect(id: "TAB_INDICATOR", in: animation)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        ExploreCategoryTabs(selectedCategory: .constant(.forYou))
        Divider()
        Spacer()
    }
}
