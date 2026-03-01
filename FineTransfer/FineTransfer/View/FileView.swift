//
//  FileView.swift
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

import SwiftUI

struct FileView: View {

    var device: MTPDevice?

    @State private var files: [MTPFileItem] = []

    var body: some View {
        FileGridView(files: files)
            .onAppear {
                loadFiles()
            }
            .onChange(of: device) {
                loadFiles()
            }
    }

    private func loadFiles() {
        guard let device else {
            files = []
            return
        }
        files = (try? device.contents(folderID: MTPDevice.rootFolderID, storageID: device.rootStorageID)) ?? []
    }
}

#Preview {
    FileView(device: nil)
}
