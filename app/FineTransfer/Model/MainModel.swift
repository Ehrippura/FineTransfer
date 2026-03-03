//
//  MainModel.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

@MainActor
@Observable
class MainModel {

    var devices: [MTPDevice] = []

    var selectedDevice: MTPDevice?

    init() {
        DeviceManager.shared.startMonitoring {
            self.detectDevices()
        }
    }

    func detectDevices() {
        Task.detached {
            do {
                let devices = try DeviceManager.shared.detectDevices()
                if let selectedDevice = await self.selectedDevice {
                    if !devices.map(\.busLocation).contains(selectedDevice.busLocation) {
                        await self.setSelectedDevice(nil)
                    }
                }
                await self.setDevices(devices)
            } catch {
                print(error)
            }
        }
    }

    func setDevices(_ devices: [MTPDevice]) {
        self.devices = devices
    }

    func setSelectedDevice(_ device: MTPDevice?) {
        guard let device else {
            self.selectedDevice = nil
            return
        }
        self.selectedDevice = devices.first(where: { $0.busLocation == device.busLocation })
    }
}
