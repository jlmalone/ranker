import SwiftUI

@main
struct RankerApp: App {

    var body: some Scene {
        WindowGroup {
            TabView {
                WordSorterContentView()
                    .tabItem {
                        Image(systemName: "slider.horizontal.3")
                        Text("Browse")
                    }

                WordCorpusView()
                    .tabItem {
                        Image(systemName: "plus.rectangle.on.folder")
                        Text("Add Words")
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
