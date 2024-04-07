//
//  PsychContentView.swift
//  Ranker
//
//  Created by Joseph Malone on 4/4/24.
//

import Foundation
import SwiftUI



import SwiftUI

struct WordSorterContentView: View {
    @StateObject var viewModel = WordSorterViewModel()
    @State private var maxWidth: CGFloat = 100 // Adjust based on content

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.fixed(maxWidth), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.fixed(30))
                ], alignment: .leading, spacing: 20) {
                    ForEach($viewModel.words) { $word in
                        Text(word.name)
                            .lineLimit(1)
                            .background(GeometryReader { geometry in
                                Color.clear.onAppear {
                                    maxWidth = max(maxWidth, geometry.size.width)
                                }
                            })

                        CustomSlider(value: $word.rank)
                            .frame(height: 20)

                        Image(systemName: word.isNotable ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .onTapGesture {
                                word.isNotable.toggle()
                            }
                    }
                }
            }
            Button("Next") {
                viewModel.saveRankings()  // This will also load the next batch
            }
        }
    }
}




//
//struct WordSorterContentView: View {
//    @StateObject var viewModel = WordSorterViewModel()
////    @StateObject var viewModel = WordSorterViewModel()
//       @State private var maxWidth: CGFloat = 100 // A default value; you might adjust this based on your content
//    var body: some View {
//        VStack {
//            ScrollView {
//                LazyVGrid(columns: [
//                    GridItem(.fixed(maxWidth), alignment: .leading),
//                    GridItem(.flexible(), alignment: .leading),
//                    GridItem(.fixed(30))
//                ], alignment: .leading, spacing: 20) {
//                    ForEach($viewModel.words) { $word in
//                        Text(word.name)
//                            .lineLimit(1)
//                            .background(GeometryReader { geometry in
//                                Color.clear.onAppear {
//                                    maxWidth = max(maxWidth, geometry.size.width)
//                                }
//                            })
//
//                        CustomSlider(value: $word.rank)
//                            .frame(height: 20)
//
//                        Image(systemName: word.isNotable ? "star.fill" : "star")
//                            .foregroundColor(.yellow)
//                            .onTapGesture {
//                                word.isNotable.toggle()
//                            }
//                    }
//                }
//                .padding()
//            }
//            Button("Next") {
//                viewModel.saveRankings()
//            }
//        }
//    }
//}
//


































//works well

//
//
//
//
//struct WordSorterContentView: View {
//    @StateObject var viewModel = WordSorterViewModel()
//    @State private var maxWidth: CGFloat = 100 // A default value; you might adjust this based on your content
//
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: [
//                GridItem(.fixed(maxWidth), alignment: .leading), // Use maxWidth for the text column
//                GridItem(.flexible(), alignment: .leading), // Slider takes up the remaining space
//                GridItem(.fixed(30)) // For the star icon
//            ], alignment: .leading, spacing: 20) {
//                ForEach($viewModel.words) { $word in
//                    Text(word.name)
//                        .lineLimit(1)
//                        .background(GeometryReader { geometry in
//                            Color.clear.onAppear {
//                                maxWidth = max(maxWidth, geometry.size.width)
//                            }
//                        })
//
//                    CustomSlider(value: $word.rank)
//                        .frame(height: 20)
//
//                    Image(systemName: word.isNotable ? "star.fill" : "star")
//                        .foregroundColor(.yellow)
//                        .onTapGesture {
//                            word.isNotable.toggle()
//                        }
//                }
//            }
//            .padding()
//        }
//    }
//}
//






























//
//import SwiftUI
//
//struct WordSorterContentView: View {
//    @StateObject var viewModel = WordSorterViewModel()
//    @State private var maxWidth: CGFloat = 0 // To store the maximum width of the words
//
//    var body: some View {
//        // Measure the maximum width of the words in a hidden view
//        let measuringView = VStack {
//            ForEach(viewModel.words, id: \.name) { word in
//                Text(word.name)
//                    .background(GeometryReader { geometry in
//                        Color.clear.onAppear {
//                            maxWidth = max(maxWidth, geometry.size.width)
//                        }
//                    })
//            }
//        }
//        .hidden() // Hide this measuring view
//
//        return ScrollView {
//            // Actual content with adjusted grid layout
//            LazyVGrid(columns: [
//                GridItem(.fixed(maxWidth), alignment: .leading), // Use maxWidth for the first column
//                GridItem(.flexible(), alignment: .leading),
//                GridItem(.fixed(30))
//            ], alignment: .leading, spacing: 20) {
//                ForEach($viewModel.words) { $word in
//                    Text(word.name)
//
//                    CustomSlider(value: $word.rank, in: 0...1)
////                    CustomSlider(value: $viewModel.words[index].rank)
////                        .frame(height: 20)
//
//                    Image(systemName: word.isNotable ? "star.fill" : "star")
//                        .foregroundColor(.yellow)
//                        .onTapGesture {
//                            word.isNotable.toggle()
//                        }
//                }
//            }
//            .padding()
//        }
//        .overlay(measuringView) // Overlay the measuring view on top of the ScrollView
//    }
//    
//    
//    
//    
//    
//    
//    
//}








//
//
//
//import SwiftUI
//
//struct WordSorterContentView: View {
//    @StateObject var viewModel = WordSorterViewModel()
//
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: [
//                GridItem(.flexible(), alignment: .leading),
//                GridItem(.fixed(30))
//            ], alignment: .leading, spacing: 20) {
//                ForEach($viewModel.words.indices, id: \.self) { index in
//                    HStack {
//                        Text(viewModel.words[index].name)
//
//                        // Use GeometryReader to capture the tap gesture accurately
//                        GeometryReader { geometry in
//                            Slider(value: $viewModel.words[index].rank, in: 0...1)
//                                .accentColor(.blue) // Optional: change the slider's accent color
//                                // Invisible layer to detect taps, using DragGesture with minimumDistance set to 0
//                                .background(Color.clear)
//                                .contentShape(Rectangle()) // Ensure the tap gesture covers the whole slider area
//                                .gesture(
//                                    DragGesture(minimumDistance: 0)
//                                        .onEnded({ drag in
//                                            // Calculate the slider value based on the tap location
//                                            let tapLocation = drag.location.x - geometry[.leading]
//                                            let sliderValue = tapLocation / geometry.size.width
//                                            viewModel.words[index].rank = Double(sliderValue).clamped(to: 0...1)
//                                        })
//                                )
//                        }.frame(height: 20) // Set a fixed height for the slider area
//                        
//                        Image(systemName: viewModel.words[index].isNotable ? "star.fill" : "star")
//                            .foregroundColor(.yellow)
//                            .onTapGesture {
//                                viewModel.words[index].isNotable.toggle()
//                            }
//                    }
//                    .frame(height: 44) // Ensuring enough tap area
//                }
//            }
//            .padding()
//        }
//    }
//}
//
////extension Double {
////    /// Clamps the value to the specified range.
////    func clamped(to limits: ClosedRange<Double>) -> Double {
////        return min(max(self, limits.lowerBound), limits.upperBound)
////    }
////}
