//
//  FileView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

struct FileView: View {

    var device: MTPDevice?

    @State private var files: [MTPFileItem] = []
    @State private var isLoading = false
    @State private var currentFolderID: UInt32 = MTPDevice.rootFolderID
    @State private var backStack: [UInt32] = []
    @State private var forwardStack: [UInt32] = []

    var body: some View {
        FileGridView(files: files)
            .onDoubleClick { item in
                if item.isFolder {
                    navigateToFolder(item.itemID)
                }
            }
            .onAppear {
                loadFiles()
            }
            .onChange(of: device) {
                resetNavigation()
                loadFiles()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(backStack.isEmpty)

                    Button(action: goForward) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(forwardStack.isEmpty)
                }

                ToolbarItem(placement: .primaryAction) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            }
    }

    private func navigateToFolder(_ folderID: UInt32) {
        backStack.append(currentFolderID)
        forwardStack.removeAll()
        currentFolderID = folderID
        loadFiles()
    }

    private func goBack() {
        guard let previousFolderID = backStack.popLast() else {
            return
        }
        forwardStack.append(currentFolderID)
        currentFolderID = previousFolderID
        loadFiles()
    }

    private func goForward() {
        guard let nextFolderID = forwardStack.popLast() else {
            return
        }
        backStack.append(currentFolderID)
        currentFolderID = nextFolderID
        loadFiles()
    }

    private func resetNavigation() {
        currentFolderID = MTPDevice.rootFolderID
        backStack.removeAll()
        forwardStack.removeAll()
    }

    private func loadFiles() {
        guard let device else {
            files = []
            return
        }

        Task {
            isLoading = true
            do {
                let items = try await device.contents(folderID: currentFolderID, storageID: device.rootStorageID)
                files = items
            } catch {
                NSAlert(error: error).runModal()
                files = []
            }
            isLoading = false
        }
    }
}

#Preview {
    FileView(device: nil)
}
