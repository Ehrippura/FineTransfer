//
//  DeviceDetailView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

struct DeviceDetailView: View {

    var device: MTPDevice

    var body: some View {
        VStack {
            if let manufacturer = device.manufacturer {
                Text(manufacturer)
            }
            if let displayName = device.displayName {
                Text(displayName)
            }
        }
    }
}
