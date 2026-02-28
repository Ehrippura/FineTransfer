//
//  MainModel.swift
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

import SwiftUI

@MainActor
@Observable
class MainModel {

    var devices: [MTPDevice] = []

    var selectedDevice: MTPDevice?

    init() {

    }

    func detectDevices() {
        Task.detached {
            do {
                let devices = try DeviceManager.shared.detectDevices()
                await self.setDevices(devices)
            } catch {
                print(error)
            }
        }
    }

    func setDevices(_ devices: [MTPDevice]) {
        self.devices = devices
    }

    func selectDevice(_ id: String) {
        selectedDevice = devices.first(where: { $0.modelName == id })
    }
}
