//
//  Test.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 3.07.2024.
//

import Foundation
import SwiftUI

struct QuitProgressView: View {
    @State private var daysSinceLastPuff: Int = 15
    @State private var withdrawalTimeline: String = "Nicotine cravings are fading. You're doing great!"

    // Additional Data Points (Example)
    @State private var moneySaved: Double = 35.75  // Replace with actual calculation
    @State private var lifeRegained: String = "5 hours"  // Replace with actual calculation

    let vapeTendencies: [(time: String, place: String)] = [ /* ... */ ] // (same as before)

    var body: some View {
        ZStack {
            // Dynamic Background Gradient (based on progress)
            LinearGradient(gradient: Gradient(colors: [
                Color(hue: 0.6 - Double(daysSinceLastPuff) / 100, saturation: 1, brightness: 0.8),
                Color(hue: 0.5, saturation: 1, brightness: 0.7)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                // Days Since Last Puff with Progress Ring
                ZStack {
                    Circle()
                        .stroke(lineWidth: 15)
                        .opacity(0.3)
                        .foregroundColor(.white)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(daysSinceLastPuff) / 30)  // Example: 30-day progress
                        .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.green)
                        .rotationEffect(Angle(degrees: -90))
                    Text("\(daysSinceLastPuff)")
                        .font(.largeTitle).fontWeight(.heavy)
                }
                .frame(height: 200)

                // ... (Withdrawal Timeline, Vape Tendencies - same as before)

                // Additional Data Points
                HStack {
                    VStack(alignment: .leading) {
                        Text("Money Saved:")
                            .font(.title3).bold()
                        Text("$\(moneySaved, specifier: "%.2f")")
                    }

                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Life Regained:")
                            .font(.title3).bold()
                        Text(lifeRegained)
                    }
                }

                // Button (Example)
                Button("View Detailed Progress") {
                    // Navigate to detailed progress view
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
            }
            .padding()
            .foregroundStyle(.white)
        }
    }
}

#Preview{
    QuitProgressView()
}
