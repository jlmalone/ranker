import SwiftUI

@main
struct RankerApp: App {

    var body: some Scene {
        WindowGroup {
            TabView {
                MemoryDumpView()
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("Dump")
                    }

                RankingContainerView()
                    .tabItem {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Ranker")
                    }

                PatternRankingView()
                    .tabItem {
                        Image(systemName: "textformat.abc")
                        Text("Patterns")
                    }

                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }

                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
        }
    }
}

struct RankingContainerView: View {
    @State private var showRanking = false

    var body: some View {
        NavigationStack {
            if showRanking {
                EloRankingView()
            } else {
                ContextPrimingView(showRanking: $showRanking)
            }
        }
    }
}
