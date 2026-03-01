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

    @State private var downloadState: DownloadState?

    var body: some View {
        FileGridView(files: files)
            .onDoubleClick { item in
                if item.isFolder {
                    navigateToFolder(item.itemID)
                }
            }
            .onDownload { filesToDownload in
                downloadFiles(filesToDownload)
            }
            .onAppear {
                loadFiles()
            }
            .onChange(of: device) {
                resetNavigation()
                loadFiles()
            }
            .sheet(item: $downloadState) { _ in
                TransferProgressView(state: $downloadState)
                    .padding()
                    .interactiveDismissDisabled(true)
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

    private func downloadFiles(_ filesToDownload: [MTPFileItem]) {

        guard let device else {
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Choose Destination", comment: "Download destination folder picker button")

        guard panel.runModal() == .OK, let destinationFolder = panel.url else {
            return
        }

        let folderName = destinationFolder.lastPathComponent

        let sessionID = UUID()

        Task {
            for (index, file) in filesToDownload.enumerated() {
                let filename = file.filename ?? "Unknown"
                let destinationURL = destinationFolder.appendingPathComponent(filename)

                do {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        let progress = device.downloadFile(id: file.itemID, to: destinationURL) { error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                        downloadState = DownloadState(
                            id: sessionID,
                            filename: filename,
                            isFolder: file.isFolder,
                            destinationFolderName: folderName,
                            progress: progress,
                            currentIndex: index,
                            totalCount: filesToDownload.count
                        )
                    }

                    // delays 0.3 seconds before sheet dismiss
                    try? await Task.sleep(for: .seconds(0.3))

                } catch {
                    NSAlert(error: error).runModal()
                    break
                }
            }
            downloadState = nil
        }
    }
}

#Preview {
    FileView(device: nil)
}
