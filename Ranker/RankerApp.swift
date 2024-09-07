
import SwiftUI
import SwiftData


@main
struct RankerApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WordSorterContentView()
            }
            .navigationViewStyle(StackNavigationViewStyle()) // For iPad compatibility
        }
    }
}
