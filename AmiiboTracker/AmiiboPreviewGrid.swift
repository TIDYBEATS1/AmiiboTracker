//
//  AmiiboPreviewGrid.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 29/06/2025.
//

import SwiftUI

struct AmiiboPreviewGrid: View {
    @State private var internalRefreshID = UUID()
    @EnvironmentObject var service: AmiiboService
    let columns = [
        GridItem(.flexible(minimum: 140, maximum: 160))
    ]
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(0..<4) { _ in
                VStack {
                    Image(systemName: "gamecontroller")
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("Amiibo")
                        .font(.caption)
                }
                .id(internalRefreshID)
            }
        }
    }
}

