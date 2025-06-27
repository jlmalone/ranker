import SwiftUI
// import SwiftData // This might not be used currently, but can stay

@main
struct RankerApp: App {

    //TODO Remove this for production code
    init() {
        #if !targetEnvironment(simulator)
        fatalError("This app is intended to run on the simulator for testing purposes.")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationView { // Keep the NavigationView wrapper for consistent styling
                TabView {
                    WordSorterContentView()
                        .tabItem {
                            Image(systemName: "list.dash")
                            Text("Ranker")
                        }

                    SearchView() // This should now refer to your newly renamed SearchView
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }

                    SettingsView() // We'll need to ensure SettingsView.swift exists from one of the branches
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle()) // For iPad compatibility
        }
    }
}
