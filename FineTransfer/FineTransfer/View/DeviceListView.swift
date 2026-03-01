//
//  DeviceListView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

struct DeviceListView: View {

    @Environment(MainModel.self) var viewModel

    @State var selection: String? = nil

    var body: some View {
        List(viewModel.devices, id: \.modelName, selection: $selection) { device in
            DeviceListRow(device: device)
        }
        .onChange(of: selection) { old, new in
            if let new {
                viewModel.selectDevice(new)
            }
        }
        .overlay {
            if viewModel.devices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "cable.connector.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.red)
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
