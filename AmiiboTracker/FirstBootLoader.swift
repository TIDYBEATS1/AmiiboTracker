import SwiftUI

struct FirstBootLoader<Content: View>: View {
    @AppStorage("hasFetchedAmiibos") private var hasFetchedAmiibos = false
    @State private var isLoading = true

    @ViewBuilder var content: () -> Content
    @EnvironmentObject var service: AmiiboService

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView("Downloading Assets…")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.4)
                        .padding()

                    Text("Please wait while we fetch Amiibo data.")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.secondarySystemFill))
            } else {
                content()
            }
        }
        .task {
            if !hasFetchedAmiibos {
                await service.fetchAmiibos(force: false)
                hasFetchedAmiibos = true
            } else {
                await service.fetchAmiibos(force: true)
            }
            isLoading = false
        }
    }
}
