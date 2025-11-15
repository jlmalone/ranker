// ranker/Ranker/Views/CollectionsView.swift

import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()

    var body: some View {
        List {
            ForEach(viewModel.collections) { collection in
                NavigationLink(destination: CollectionDetailView(collection: collection, viewModel: viewModel)) {
                    HStack {
                        Image(systemName: collection.isSystem ? "star.fill" : "folder.fill")
                            .foregroundColor(collection.isSystem ? .yellow : .blue)

                        VStack(alignment: .leading) {
                            Text(collection.name)
                                .font(.headline)
                            Text("\(collection.words.count) words")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let collection = viewModel.collections[index]
                    viewModel.deleteCollection(collection)
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.showingNewCollectionSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingNewCollectionSheet) {
            NewCollectionSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadCollections()
        }
    }
}

// MARK: - Collection Detail View

struct CollectionDetailView: View {
    let collection: WordCollection
    @ObservedObject var viewModel: CollectionsViewModel
    @State private var showingAddWord = false
    @State private var newWord = ""
    @State private var showingExport = false

    var body: some View {
        VStack {
            List {
                Section(header: Text(collection.description)) {
                    ForEach(collection.words, id: \.self) { word in
                        HStack {
                            Text(word)
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                viewModel.removeWordFromCollection(word: word, collectionId: collection.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            if collection.words.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No words in this collection")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle(collection.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddWord = true }) {
                        Label("Add Word", systemImage: "plus")
                    }

                    Button(action: {
                        viewModel.exportCollection(collection)
                        showingExport = true
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordSheet(collectionId: collection.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showingExport) {
            if let exportData = viewModel.exportData {
                ShareSheet(items: [exportData])
            }
        }
    }
}

// MARK: - New Collection Sheet

struct NewCollectionSheet: View {
    @ObservedObject var viewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Collection Details") {
                    TextField("Name", text: $viewModel.newCollectionName)
                    TextField("Description", text: $viewModel.newCollectionDescription)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createCollection()
                        dismiss()
                    }
                    .disabled(viewModel.newCollectionName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Word Sheet

struct AddWordSheet: View {
    let collectionId: Int64
    @ObservedObject var viewModel: CollectionsViewModel
    @State private var newWord = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Word", text: $newWord)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        viewModel.addWordToCollection(word: newWord, collectionId: collectionId)
                        dismiss()
                    }
                    .disabled(newWord.isEmpty)
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
