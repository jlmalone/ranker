//
//  CustomSlider.swift
//  Ranker
//
//  Created by Joseph Malone on 4/4/24.
//

import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double // The current value of the slider, ranging from 0 to 1.
    var range: ClosedRange<Double> = 0...1 // Defines the range of the slider.
    var onEditingChanged: (Bool) -> Void = { _ in } // Callback for the start and end of editing.

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle() // Represents the slider track.
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(height: 5)
                
                Rectangle() // Represents the filled portion of the slider track.
                    .foregroundColor(.blue)
                    .frame(width: CGFloat(value) * geometry.size.width, height: 5)
                
                Circle() // Represents the slider thumb.
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat(value) * geometry.size.width - 10)
            }
            .contentShape(Rectangle()) // Makes the entire slider area responsive to input.
            .gesture(
                DragGesture(minimumDistance: 0) // Captures both drag and tap gestures.
                    .onChanged({ value in
                        let sliderPosition = value.location.x / geometry.size.width
                        let newValue = sliderPosition * (range.upperBound - range.lowerBound) + range.lowerBound
                        self.value = newValue.clamped(to: range)
                        onEditingChanged(true)
                    })
                    .onEnded({ _ in onEditingChanged(false) })
            )
        }
        .frame(height: 20) // Sets a fixed height for the slider.
    }
}

extension Double {
    /// Clamps the Double value to the specified limits.
    func clamped(to limits: ClosedRange<Double>) -> Double {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
