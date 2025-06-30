//
//  AmiiboPreviewList.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 29/06/2025.
//

import SwiftUI


struct AmiiboPreviewList:  View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "figure.wave")
                Text("Mario")
            }
            Divider()
            HStack {
                Image(systemName: "figure.wave")
                Text("Zelda")
            }
        }
        .padding()
    }
}
