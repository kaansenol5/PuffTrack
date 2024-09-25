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
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
            socialsViewModel.sendEvent(event: "getPuffCount")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [self] in
        
            let unsyncedPuffCount = puffTrackViewModel.model.puffs.count - socialsViewModel.serverPuffCount
            if(unsyncedPuffCount < 0){
                return
                //TODO: handle this 
            }
            let unsyncedPuffs: [Puff] = puffTrackViewModel.model.puffs.suffix(unsyncedPuffCount)
            if unsyncedPuffs.isEmpty{
                return
            }
            print("Syncing \(unsyncedPuffs.count) puffs")
            let timestamps = unsyncedPuffs.map { Int($0.timestamp.timeIntervalSince1970 * 1000) }
            socialsViewModel.sendEvent(event: "addPuffs", withData: ["puffs":timestamps])
            syncing = false
        }
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
