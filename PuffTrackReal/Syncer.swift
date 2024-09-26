//
//  Syncer.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 23.09.2024.
//

import Foundation
import Combine
import SwiftUICore

class Syncer: ObservableObject {
    private var puffTrackViewModel: PuffTrackViewModel
    private var socialsViewModel: SocialsViewModel
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var syncing = false
    init(puffTrackViewModel: PuffTrackViewModel, socialsViewModel: SocialsViewModel) {
        self.puffTrackViewModel = puffTrackViewModel
        self.socialsViewModel = socialsViewModel
      //  setupTimer()
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.syncUnsynedPuffs()
        }
    }

    func syncUnsynedPuffs() {
        if(syncing){
            return
        }
        syncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: { [ self] in
            let unsyncedPuffs = puffTrackViewModel.model.puffs.filter { !$0.isSynced }
            let puffData = unsyncedPuffs.map { puff in
                return [
                    "id": puff.id.uuidString, // convert UUID to a string
                    "timestamp": Int(puff.timestamp.timeIntervalSince1970), // convert timestamp to seconds since 1970
                    "isSynced": puff.isSynced
                ] as [String : Any] // explicitly declare the dictionary type
            }
            socialsViewModel.sendEvent(event: "addPuffs", withData: ["puffs": puffData])
        })

        
        DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: { [ self] in
            for (index, puff) in puffTrackViewModel.model.puffs.enumerated() {
                if socialsViewModel.lastSyncedPuffs.contains(puff.id.uuidString) {
                    // Create a mutable copy of puff
                    var updatedPuff = puff
                    print("puffsync")
                    // Modify the isSynced property
                    updatedPuff.isSynced = true
                    // Replace the original puff in the array
                    puffTrackViewModel.model.puffs[index] = updatedPuff
                }
            }
            syncing = false
        })
        

    }

    func startSync() {
        timer?.fire() // Trigger an immediate sync
    }

    func stopSync() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopSync()
    }
}
