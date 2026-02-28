//
//  FileView.swift
//  FineTransfer
//
//  Created by Wayne Lin on 2026/2/28.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct FileView: View {

    @State var device: MTPDevice?

    @State var files: [MTPFileItem] = []

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: [
                .init(.adaptive(minimum: 100, maximum: .infinity), spacing: 8)
            ]) {
                ForEach(files, id: \.itemID) { file in
                    VStack {
                        if file.isFolder {
                            folderImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.blue)
                        }
                        Text(file.filename ?? "Unknown File")
                            .font(.headline)
                    }
                }
            }
            .padding(8)
        }
        .onAppear {
            guard let device else {
                return
            }

            files = (try? device.contents(folderID: MTPDevice.rootFolderID, storageID: device.rootStorageID)) ?? []
        }
    }

    var folderImage: Image {
        let image = NSWorkspace.shared.icon(for: .folder)
        return Image(nsImage: image)
    }
}

#Preview {
    FileView(device: nil)
}
