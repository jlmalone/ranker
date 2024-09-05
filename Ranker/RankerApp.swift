
import SwiftUI
import SwiftData

//@main
//struct RankerApp: App {
//    var body: some Scene {
//        WindowGroup {
//            NavigationView {
//                WordSorterContentView()
//            }
//            .navigationViewStyle(StackNavigationViewStyle()) // This forces a full-width style on iPad
//        }
//    }
//}


@main
struct RankerApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                
                TabView {
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
            .navigationViewStyle(StackNavigationViewStyle()) // For iPad compatibility
        }
    }
}
