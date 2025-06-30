//
//  AmiiboPreviewDetail.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 29/06/2025.
//


import SwiftUI

struct AmiiboPreviewDetail: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mario")
                .font(.headline)
            Text("Series: Super Mario")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Divider()
            Text("Zelda")
                .font(.headline)
            Text("Series: The Legend of Zelda")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
