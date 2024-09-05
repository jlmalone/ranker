//
//  SearchView.swift
//  Ranker
//
//  Created by Agent Malone on 9/4/24.
//

import Foundation
import SwiftUI

struct SearchView: View {
    @StateObject var viewModel = SearchViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack {
            TextField("Search for a word", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            List {
                ForEach(viewModel.searchResults) { word in
                    NavigationLink(destination: WordAssociationView(word: word)) {
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


//todo
//class SearchViewModel: ObservableObject {
//    @Published var searchResults: [Word] = []
//    
//    private let databaseManager = DatabaseManager()
//
//    func search(for query: String) {
//        // Implement search logic based on the word association database
//        searchResults = databaseManager.fetchUnrankedAssociations(batchSize: 10).filter { $0.name.contains(query) }
//    }
//}


class SearchViewModel: ObservableObject {
    @Published var searchResults: [Word] = []
    
    private let databaseManager = DatabaseManager()

    func search(for query: String) {
        print("Searching for: \(query)") // Debugging log to ensure the query is correct
        guard !query.isEmpty else {
            searchResults = [] // If the query is empty, clear results
            return
        }

        searchResults = databaseManager.searchWords(query: query)
        print("Found results: \(searchResults)") // Debugging log to check the results
    }
}





//ALT TODO
//
//struct SearchView: View {
//    @StateObject var viewModel = SearchViewModel()
//    @State private var searchText = ""
//
//    var body: some View {
//        VStack {
//            TextField("Search for a word", text: $searchText)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            List {
//                ForEach(viewModel.searchResults) { word in
//                    NavigationLink(destination: WordAssociationView(word: word)) {
//                        Text(word.name)
//                    }
//                }
//            }
//            .onChange(of: searchText) { oldText, newText in
//                if newText != oldText {
//                    print("Search text changed to: \(newText)")
//                    viewModel.search(for: newText)
//                }
//            }
//        }
//        .onAppear {
//            print("SearchView appeared")
//        }
//    }
//}
//
//class SearchViewModel: ObservableObject {
//    @Published var searchResults: [Word] = []
//    
//    private let databaseManager = DatabaseManager()
//
//    func search(for query: String) {
//        guard !query.isEmpty else {
//            print("Empty query, no search performed.")
//            searchResults = []
//            return
//        }
//        print("Performing search for query: \(query)")
//        searchResults = databaseManager.fetchUnrankedAssociations(batchSize: 10).filter { $0.name.contains(query) }
//        print("Search results: \(searchResults)")
//    }
//}
