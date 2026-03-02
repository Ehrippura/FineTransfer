//
//  DeviceListView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

struct DeviceListView: View {

    @Environment(MainModel.self) var viewModel

    var body: some View {

        @Bindable var model = viewModel

        List(viewModel.devices, id: \.modelName, selection: $model.selectedDevice) { device in
            DeviceListRow(device: device)
                .id(device)
        }
        .overlay {
            if viewModel.devices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "cable.connector.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.red)
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.bounce.up.byLayer, options: .nonRepeating)
                    Text("No devices connected")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}

#Preview {
    DeviceListView()
}
