
import SwiftUI
import SwiftData


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
            NavigationView {
                WordSorterContentView()
            }
            .navigationViewStyle(StackNavigationViewStyle()) // For iPad compatibility
        }
    }
}
