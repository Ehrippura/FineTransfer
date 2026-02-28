//
//  ContentView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

struct MainView: View {

    @State var columnVisible: NavigationSplitViewVisibility = .all

    var model: MainModel = .init()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisible) {
            DeviceListView()
                .environment(model)
        } detail: {
            if let device = model.selectedDevice {
                FileView(device: device)
            } else {
                Text("Select a device")
            }
        }
        .onAppear {
            model.detectDevices()
        }
    }
}

#Preview {
    MainView()
}
