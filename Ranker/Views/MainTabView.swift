// ranker/Ranker/Views/MainTabView.swift

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                WordSorterContentView()
            }
            .tabItem {
                Label("Rank", systemImage: "slider.horizontal.3")
            }

            NavigationView {
                DictionaryView()
            }
            .tabItem {
                Label("Dictionary", systemImage: "book.closed")
            }

            NavigationView {
                GamesView()
            }
            .tabItem {
                Label("Games", systemImage: "gamecontroller")
            }

            NavigationView {
                LearningView()
            }
            .tabItem {
                Label("Learn", systemImage: "graduationcap")
            }

            NavigationView {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationView {
                CollectionsView()
            }
            .tabItem {
                Label("Lists", systemImage: "folder")
            }
        }
    }
}
