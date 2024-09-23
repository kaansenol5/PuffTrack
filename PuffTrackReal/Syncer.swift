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

    init(puffTrackViewModel: PuffTrackViewModel, socialsViewModel: SocialsViewModel) {
        self.puffTrackViewModel = puffTrackViewModel
        self.socialsViewModel = socialsViewModel
        setupTimer()
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.syncUnsynedPuffs()
        }
    }

    func syncUnsynedPuffs() {
        let unsyncedPuffs = puffTrackViewModel.model.puffs.filter { !$0.isSynced }
        if unsyncedPuffs.isEmpty{
            print("not syncing")
            print(unsyncedPuffs)
            return
        }

        let puffTimestamps = unsyncedPuffs.map { $0.timestamp.timeIntervalSince1970 }
        print("syncing")

        socialsViewModel.sendEvent(event: "addPuffs", withData: ["puffs": puffTimestamps])

        // Mark puffs as synced locally
        for puff in unsyncedPuffs {
            if let index = puffTrackViewModel.model.puffs.firstIndex(where: { $0.id == puff.id }) {
                puffTrackViewModel.model.puffs[index].isSynced = true
            }
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
