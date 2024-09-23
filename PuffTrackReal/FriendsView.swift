//
//  FriendsView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 14.09.2024.
//

import Foundation
import SwiftUI

struct FriendsView: View {
    
    @State var friendIdToAdd: String = ""

    @ObservedObject var socialsViewModel: SocialsViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    
                    addFriendSection
                    
                    incomingRequestsSection
                    
                    outgoingRequestsSection
                    
                    friendsListSection
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 5) {
            Text("Your User ID:")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(socialsViewModel.serverData?.user.id ?? "Loading...")
                .font(.headline)
                .foregroundColor(textColor)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = socialsViewModel.serverData?.user.id
                    }) {
                        Text("Copy User ID")
                        Image(systemName: "doc.on.doc")
                    }
                }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(10)
    }
    
    private var addFriendSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Add Friend")
                .font(.headline)
                .foregroundColor(textColor)
            
            HStack {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.gray)
                TextField("Enter User ID", text: $friendIdToAdd)
                    .foregroundColor(textColor)
                    .autocapitalization(.none)
            }
            .padding()
            .background(fieldBackgroundColor)
            .cornerRadius(10)
            
            Button(action: {
                socialsViewModel.sendEvent(event: "addFriend", withData: ["friendId": friendIdToAdd])
            }) {
                Text("SEND FRIEND REQUEST")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(10)
    }
    
    private var incomingRequestsSection: some View {
        Group {
            if !(socialsViewModel.serverData?.receivedFriendRequests.isEmpty ?? false) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Incoming Friend Requests")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    ForEach(socialsViewModel.serverData?.receivedFriendRequests ?? []) { request in
                        IncomingRequestRow(request: request, socialsViewModel: socialsViewModel)
                    }
                }
                .padding()
                .background(cardBackgroundColor)
                .cornerRadius(10)
            }
        }
    }
    private var outgoingRequestsSection: some View {
         Group {
             if !(socialsViewModel.serverData?.sentFriendRequests.isEmpty ?? false) {
                 VStack(alignment: .leading, spacing: 15) {
                     Text("Outgoing Friend Requests")
                         .font(.headline)
                         .foregroundColor(textColor)
                     
                     ForEach(socialsViewModel.serverData?.sentFriendRequests ?? []) { request in
                         OutgoingRequestRow(request: request, cancelAction: {
                             // Handle cancel action
                         })
                     }
                 }
                 .padding()
                 .background(cardBackgroundColor)
                 .cornerRadius(10)
             }
         }
     }
     
    private var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Friends")
                .font(.headline)
                .foregroundColor(textColor)
            
            ForEach(socialsViewModel.serverData?.friends ?? []) { friend in
                FriendRow(friend: friend)
                // restructure data., puff summaries in friends
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(10)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.9) : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05)
    }
    
    private var fieldBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }
}

// MARK: - Subviews

struct FriendRow: View {
    var friend: Friend
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(getInitials(from: friend.name))
                        .foregroundColor(.white)
                        .font(.headline)
                )
            VStack(alignment: .leading, spacing: 5) {
                Text(friend.name)
                    .foregroundColor(textColor)
                    .font(.headline)
                Text("\(friend.puffsummary.puffsToday) puffs today")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(Int(friend.puffsummary.changePercentage) ?? 0 >= 0 ? "+" : "")\(friend.puffsummary.changePercentage)%")
                .foregroundColor(Int(friend.puffsummary.changePercentage) ?? 0 >= 0 ? .green : .red)
                .font(.subheadline)
        }
        .padding(.vertical, 5)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

struct IncomingRequestRow: View {
    var request: FriendRequest
    @ObservedObject var socialsViewModel: SocialsViewModel
    func acceptAction(){
        socialsViewModel.sendEvent(event: "acceptRequest", withData: ["requestId": request.id])
    }
    func declineAction(){
        socialsViewModel.sendEvent(event: "declineRequest", withData: ["requestId": request.id])
    }
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(getInitials(from: request.sender?.name ?? "0"))
                        .foregroundColor(.white)
                        .font(.headline)
                )
            Text(request.sender?.name ?? "default value")
                .foregroundColor(textColor)
                .font(.headline)
            Spacer()
            Button(action: acceptAction) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            Button(action: declineAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.vertical, 5)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

struct OutgoingRequestRow: View {
    var request: FriendRequest
    var cancelAction: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(getInitials(from: request.receiver?.name ?? "value"))
                        .foregroundColor(.white)
                        .font(.headline)
                )
            Text(request.receiver?.name ?? "value")
                .foregroundColor(textColor)
                .font(.headline)
            Spacer()
            Button(action: cancelAction) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .padding(.vertical, 5)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
}



func getInitials(from name: String) -> String {
    let words = name.split(separator: " ")
    let initials = words.compactMap { $0.first }
    return String(initials)
}


#Preview {
    FriendsView(socialsViewModel: SocialsViewModel())
}
