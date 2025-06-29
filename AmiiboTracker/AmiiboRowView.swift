//
//  AmiiboRowView.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 25/06/2025.
//


// AmiiboRowView.swift
import SwiftUI

struct AmiiboRowView: View {
    let amiibo: Amiibo
    let isOwned: Bool
    let toggleAction: () -> Void

    var body: some View {
        HStack {
            Button(action: toggleAction) {
                Image(systemName: isOwned ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOwned ? .green : .gray)
            }
            .buttonStyle(.plain)

            AsyncImage(url: URL(string: amiibo.image)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    Color.gray.opacity(0.2)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.trailing, 4)
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.trailing, 4)

            VStack(alignment: .leading) {
                Text(amiibo.name).font(.headline)
                Text("Series: \(amiibo.gameSeries)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
