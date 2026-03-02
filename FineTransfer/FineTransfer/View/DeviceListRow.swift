//
//  DeviceListRow.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI


struct DeviceListRow: View {

    weak var device: MTPDevice?

    var body: some View {
        HStack {

            Image(systemName: "externaldrive.connected.to.line.below")

            VStack(alignment: .leading) {
                if let manufacturer = device?.manufacturer {
                    Text(manufacturer)
                }
                if let displayName = device?.displayName, !displayName.isEmpty {
                    Text(displayName)
                } else if let modelName = device?.modelName {
                    Text(modelName.isEmpty ? "Unknown" : modelName)
                }
            }
        }
    }
}
