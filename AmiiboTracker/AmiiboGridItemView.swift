//
//  AmiiboGridItemView.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 27/06/2025.
//


import SwiftUI

struct AmiiboGridItemView: View {
    let amiibo: Amiibo
    let isOwned: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: amiibo.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            isOwned ? RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 2) : nil
                        )
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            Text(amiibo.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100)
        .onTapGesture { onTap() }
    }
}
