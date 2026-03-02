import SwiftUI

@main
struct RankerApp: App {

    var body: some Scene {
        WindowGroup {
            NavigationView {
                TabView {
                    MemoryDumpView()
                        .tabItem {
                            Image(systemName: "brain.head.profile")
                            Text("Dump")
                        }

                    WordSorterContentView()
                        .tabItem {
                            Image(systemName: "list.dash")
                            Text("Ranker")
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
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
