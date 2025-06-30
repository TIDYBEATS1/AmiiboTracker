//
//  AmiiboCard.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 29/06/2025.
//


import SwiftUI
import Foundation

struct AmiiboCard: View {
    let amiibo: Amiibo
    @EnvironmentObject var service: AmiiboService
    
    var isOwned: Bool {
        service.ownedAmiiboIDs.contains(amiibo.id)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: amiibo.image)) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .transaction { transaction in
                transaction.disablesAnimations = true // ✅ Prevent flicker and delays
            }
            
            Text(amiibo.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            if isOwned {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemFill)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOwned ? Color.green : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            service.toggleOwnership(for: amiibo)
        }
        .id(amiibo.id) // 👈 Forces view refresh if needed
    }
    
    private var placeholder: some View {
        Color.gray
            .opacity(0.2)
            .overlay(Image(systemName: "photo"))
    }
}
