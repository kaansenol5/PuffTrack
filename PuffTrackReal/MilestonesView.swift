//
//  Views.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 27.08.2024.
//

import Foundation
import SwiftUI

import SwiftUI

import SwiftUI

struct MilestonesView: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.milestones) { milestone in
                        MilestoneCard(milestone: milestone)
                    }
                }
                .padding()
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationTitle("Milestones")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.9) : Color.white
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(milestone.isAchieved ? Color.red : Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if milestone.isAchieved {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 30, weight: .bold))
                        } else {
                            Text("\(milestone.days)")
                                .foregroundColor(.secondary)
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                )
            
            Text(milestone.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(milestone.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 180)
        .padding()
        .background(cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white
    }
}
