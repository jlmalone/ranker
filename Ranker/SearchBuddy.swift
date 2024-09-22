import Foundation
import SwiftUI

// //TODO code not working
// Please look at the intention mentioned intline. I only made this
// Becasue SearchAdventureView was not being recognised. WTF

struct SearchBuddy: View{

    @StateObject var viewModel = SearchBuddyViewModel()
    @State private var searchText = ""


    var body: some View {
        VStack {
            TextField("Search for a word", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            List {
                ForEach(viewModel.searchResults) { word in

                    //TODO I want an extra field with the current number value of ranking the the word being displayed.
                    //if i click the number, then up comes a view of WordRankWidget where i can change that value.
                    // it should be a page that looks a lot like WordSorterContentView, but it only shows the one row
                    // rather than batches of words. The clickable numeric rank displaying on the SearchAdventureView
                    //occurs to the very right, so we have a fow with the current Navigation Link below, followed by anotehr NabigationLink

                    NavigationLink(destination: AssociatedIdeasView(word: word.name)) {
                        Text(word.name)
                    }
                }
            }
            .onChange(of: searchText) { oldText, newText in // Use two-parameter version
                if newText != oldText {
                    viewModel.search(for: newText)
                }
            }
        }
    }

}
