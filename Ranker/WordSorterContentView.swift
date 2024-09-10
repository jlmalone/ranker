import Foundation
import SwiftUI

struct WordSorterContentView: View {
    @StateObject var viewModel = WordSorterViewModel()
    @State private var maxWidth: CGFloat = 100 // Adjust based on content
    @State private var showingShareSheet = false // State to control the ShareSheet

    @State private var showingSearchView = false // State to control the SearchSheet
    @State private var showProgressView = false // State to control navigation to ProgressView

    let databaseManager = DatabaseManager()

    var body: some View {
        NavigationStack {  // Use NavigationStack to enable navigation
            VStack {
                // Custom Title Bar
                HStack {
                    Button(action: {
                        self.showProgressView = true
                    }) {
                        Image(systemName: "chart.bar") // System image for progress
                            .imageScale(.large)
                            .padding()
                    }
                    .background(NavigationLink(destination: ProgressView(), isActive: $showProgressView) { EmptyView() })

                    Spacer()

                    Button(action: {
                        self.showingSearchView = true
                    }) {
                        Image(systemName: "magnifyingglass") // change to System image for search eg magnifying glass. TODO check
                            .imageScale(.large)
                            .padding()
                    }

                    Button(action: {
                        self.showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up") // System image for sharing
                            .imageScale(.large)
                            .padding()
                    }
                }

                // Your content
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.fixed(maxWidth), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.fixed(30))
                    ], alignment: .leading, spacing: 20) {
                        ForEach($viewModel.words) { $word in

                            //TODO the below three widgets should be consolidated into a single widget
                            //we will call it WordRankWidget
                            //This can then be reused in other places.


                            // NavigationLink to navigate to AssociatedIdeasView on click
                            NavigationLink(destination: AssociatedIdeasView(word: word.name)) {
                                Text(word.name)
                                    .lineLimit(1)
                                    .background(GeometryReader { geometry in
                                        Color.clear.onAppear {
                                            maxWidth = max(maxWidth, geometry.size.width)
                                        }
                                    })
                            }

                            CustomSlider(value: $word.rank)
                                .frame(height: 20)

                            Image(systemName: word.isNotable ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    word.isNotable.toggle()
                                }
                        }
                    }
                }

                Button("Next") {
                    viewModel.saveRankings()  // This will also load the next batch
                }.padding()
            }
            .padding()
            .sheet(isPresented: $showingShareSheet) {
                let dbPath = databaseManager.databasePath()
                ShareSheet(items: [URL(fileURLWithPath: dbPath)])

            }
        }
    }
}
