//
//  FileViewModel.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/3/2.
//

import SwiftUI

@MainActor
@Observable
class FileViewModel {

    var files: [MTPFileItem] = []
    var isLoading = false
    var currentStorage: MTPStorage?
    var downloadState: TransferState?

    var backStack: [(id: UInt32, name: String)] = []
    var forwardStack: [(id: UInt32, name: String)] = []

    private(set) var currentFolderID: UInt32 = MTPDevice.rootFolderID
    private(set) var currentFolderName: String = ""

    private(set) var device: MTPDevice?

    func setDevice(_ device: MTPDevice?) {
        self.device = device
        currentStorage = device?.storages.first
        resetNavigation()
        loadFiles()
    }

    func navigateToFolder(_ item: MTPFileItem) {
        backStack.append((id: currentFolderID, name: currentFolderName))
        forwardStack.removeAll()
        currentFolderID = item.itemID
        currentFolderName = item.filename ?? ""
        loadFiles()
    }

    func goBack() {
        guard let previous = backStack.popLast() else {
            return
        }
        forwardStack.append((id: currentFolderID, name: currentFolderName))
        currentFolderID = previous.id
        currentFolderName = previous.name
        loadFiles()
    }

    func goForward() {
        guard let next = forwardStack.popLast() else {
            return
        }
        backStack.append((id: currentFolderID, name: currentFolderName))
        currentFolderID = next.id
        currentFolderName = next.name
        loadFiles()
    }

    func loadFiles() {
        guard let device, let currentStorage else {
            files = []
            return
        }

        Task {
            isLoading = true
            do {
                let items = try await device.contents(folderID: currentFolderID, storageID: currentStorage.storageID)
                files = items
            } catch {
                NSAlert(error: error).runModal()
                files = []
            }
            isLoading = false
        }
    }

    func downloadFiles(_ filesToDownload: [MTPFileItem]) {

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
                        downloadState = TransferState(
                            id: sessionID,
                            filename: filename,
                            isFolder: file.isFolder,
                            destinationFolderName: folderName,
                            progress: progress,
                            currentIndex: index,
                            totalCount: filesToDownload.count
                        )
                    }

                    // delays 0.2 seconds before sheet dismiss
                    try? await Task.sleep(for: .seconds(0.2))

                } catch {
                    NSAlert(error: error).runModal()
                    break
                }
            }
            downloadState = nil
        }
    }

    func deleteFiles(_ filesToDelete: [MTPFileItem]) {

        guard let device else {
            return
        }

        let alert = NSAlert()
        if filesToDelete.count == 1 {
            let name = filesToDelete[0].filename ?? NSLocalizedString("file", comment: "Generic file noun")
            alert.messageText = String(format: NSLocalizedString("Delete \"%@\"?", comment: "Delete single item confirmation title"), name)
        } else {
            alert.messageText = String(format: NSLocalizedString("Delete %d items?", comment: "Delete multiple items confirmation title"), filesToDelete.count)
        }
        alert.informativeText = NSLocalizedString("This action cannot be undone.", comment: "Delete confirmation detail")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: "Delete confirmation button"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel button"))

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        Task {
            for file in filesToDelete {
                do {
                    try await device.deleteObject(id: file.itemID)
                } catch {
                    NSAlert(error: error).runModal()
                    break
                }
            }
            loadFiles()
        }
    }

    func uploadFiles() {

        guard let device, let currentStorage else {
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = NSLocalizedString("Upload", comment: "Upload files picker button")

        guard panel.runModal() == .OK, !panel.urls.isEmpty else {
            return
        }

        let filesToUpload = panel.urls
        let destinationName = currentFolderName.isEmpty ? (device.displayName ?? "Device") : currentFolderName
        let sessionID = UUID()

        Task {
            for (index, url) in filesToUpload.enumerated() {
                let filename = url.lastPathComponent

                do {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        let progress = device.uploadFile(from: url, toFolderID: currentFolderID, storageID: currentStorage.storageID) { error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                        downloadState = TransferState(
                            id: sessionID,
                            filename: filename,
                            isFolder: false,
                            destinationFolderName: destinationName,
                            progress: progress,
                            currentIndex: index,
                            totalCount: filesToUpload.count
                        )
                    }

                    // delays 0.2 seconds before sheet dismiss
                    try? await Task.sleep(for: .seconds(0.2))

                } catch {
                    NSAlert(error: error).runModal()
                    break
                }
            }
            downloadState = nil
            loadFiles()
        }
    }

    // MARK: - Private

    private func resetNavigation() {
        currentFolderID = MTPDevice.rootFolderID
        currentFolderName = ""
        backStack.removeAll()
        forwardStack.removeAll()
    }
}
