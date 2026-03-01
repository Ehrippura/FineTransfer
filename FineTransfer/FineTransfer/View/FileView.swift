//
//  FileView.swift
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

import SwiftUI

struct FileView: View {

    @State var device: MTPDevice?

    @State var files: [MTPFileItem] = []

    var body: some View {
        FileGridView(files: files)
            .onAppear {
                guard let device else {
                    return
                }
                files = (try? device.contents(folderID: MTPDevice.rootFolderID, storageID: device.rootStorageID)) ?? []
            }
    }
}

#Preview {
    FileView(device: nil)
}
