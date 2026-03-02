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
    var transferState: TransferState?

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

    func downloadFiles(_ fileToDownload: [MTPFileItem]) {

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Choose Destination", comment: "Download destination folder picker button")

        guard panel.runModal() == .OK, let destinationFolder = panel.url else {
            return
        }

        let pairs = fileToDownload.map { (file: $0, destination: destinationFolder) }

        Task {
            try? await downloadFiles(pairs)
        }
    }

    func downloadFiles(_ filesToDownload: [(file: MTPFileItem, destination: URL)]) async throws {

        guard let device else {
            return
        }

        let storageID = currentStorage?.storageID ?? 0
        defer {
            transferState = nil
        }

        let sessionID = UUID()

        for (index, entry) in filesToDownload.enumerated() {
            let file = entry.file
            let destination = entry.destination
            let filename = file.filename ?? "Unknown"

            if file.isFolder {
                do {
                    let isDirectory = (try? destination.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                    let parentDir = isDirectory ? destination : destination.deletingLastPathComponent()
                    try await downloadFolderItem(
                        file, to: parentDir, storageID: storageID,
                        sessionID: sessionID, batchIndex: index, batchTotal: filesToDownload.count
                    )
                } catch {
                    NSAlert(error: error).runModal()
                    throw error
                }
            } else {
                let isDirectory = (try? destination.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                let destinationURL = isDirectory ? destination.appendingPathComponent(filename) : destination
                let folderName = isDirectory ? destination.lastPathComponent : destination.deletingLastPathComponent().lastPathComponent

                do {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        let progress = device.downloadFile(id: file.itemID, to: destinationURL) { error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                        transferState = TransferState(
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
                    throw error
                }
            }
        }
    }

    private func downloadFolderItem(
        _ item: MTPFileItem,
        to destinationParent: URL,
        storageID: UInt32,
        sessionID: UUID,
        batchIndex: Int,
        batchTotal: Int
    ) async throws {
        guard let device else {
            return
        }

        let folderName = item.filename ?? "Folder"
        let localFolder = destinationParent.appendingPathComponent(folderName)
        try FileManager.default.createDirectory(at: localFolder, withIntermediateDirectories: true)

        let contents = try await device.contents(folderID: item.itemID, storageID: storageID)

        for child in contents {
            if child.isFolder {
                try await downloadFolderItem(
                    child, to: localFolder, storageID: storageID,
                    sessionID: sessionID, batchIndex: batchIndex, batchTotal: batchTotal
                )
            } else {
                let filename = child.filename ?? "file"
                let destFile = localFolder.appendingPathComponent(filename)
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let progress = device.downloadFile(id: child.itemID, to: destFile) { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                    transferState = TransferState(
                        id: sessionID,
                        filename: filename,
                        isFolder: false,
                        destinationFolderName: folderName,
                        progress: progress,
                        currentIndex: batchIndex,
                        totalCount: batchTotal
                    )
                }
            }
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
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = NSLocalizedString("Upload", comment: "Upload files picker button")

        guard panel.runModal() == .OK, !panel.urls.isEmpty else {
            return
        }

        uploadFiles(urls: panel.urls)
    }

    func renameFile(_ file: MTPFileItem) {
        guard let device else {
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Rename", comment: "Rename dialog title")
        alert.addButton(withTitle: NSLocalizedString("Rename", comment: "Rename confirmation button"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel button"))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        textField.stringValue = file.filename ?? ""
        textField.selectText(nil)
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty, newName != file.filename else {
            return
        }

        Task {
            do {
                try await device.renameObject(id: file.itemID, newName: newName)
                loadFiles()
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    func createFolder() {
        guard let device, let currentStorage else {
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("New Folder", comment: "New folder dialog title")
        alert.addButton(withTitle: NSLocalizedString("Create", comment: "Create folder button"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel button"))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        textField.stringValue = NSLocalizedString("untitled folder", comment: "Default new folder name")
        textField.selectText(nil)
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let name = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        Task {
            do {
                _ = try await device.createFolder(name: name, parentID: currentFolderID, storageID: currentStorage.storageID)
                loadFiles()
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    func uploadFiles(urls: [URL]) {

        guard let device, let currentStorage else {
            return
        }

        let destinationName = currentFolderName.isEmpty ? (device.displayName ?? "Device") : currentFolderName
        let sessionID = UUID()

        Task {
            for (index, url) in urls.enumerated() {
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                do {
                    if isDirectory {
                        try await uploadFolderItem(
                            url,
                            toParentID: currentFolderID,
                            storageID: currentStorage.storageID,
                            destinationName: destinationName,
                            sessionID: sessionID,
                            batchIndex: index,
                            batchTotal: urls.count
                        )
                    } else {
                        let filename = url.lastPathComponent
                        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                            let progress = device.uploadFile(from: url, toFolderID: currentFolderID, storageID: currentStorage.storageID) { error in
                                if let error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume()
                                }
                            }
                            transferState = TransferState(
                                id: sessionID,
                                filename: filename,
                                isFolder: false,
                                destinationFolderName: destinationName,
                                progress: progress,
                                currentIndex: index,
                                totalCount: urls.count
                            )
                        }

                        // delays 0.2 seconds before sheet dismiss
                        try? await Task.sleep(for: .seconds(0.2))
                    }
                } catch {
                    NSAlert(error: error).runModal()
                    break
                }
            }
            transferState = nil
            loadFiles()
        }
    }

    private func uploadFolderItem(
        _ localFolderURL: URL,
        toParentID parentID: UInt32,
        storageID: UInt32,
        destinationName: String,
        sessionID: UUID,
        batchIndex: Int,
        batchTotal: Int
    ) async throws {
        guard let device else {
            return
        }

        let folderName = localFolderURL.lastPathComponent
        let newFolderID = try await device.createFolder(name: folderName, parentID: parentID, storageID: storageID)

        let contents = try FileManager.default.contentsOfDirectory(
            at: localFolderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )

        for itemURL in contents {
            let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            if isDirectory {
                try await uploadFolderItem(
                    itemURL,
                    toParentID: newFolderID,
                    storageID: storageID,
                    destinationName: folderName,
                    sessionID: sessionID,
                    batchIndex: batchIndex,
                    batchTotal: batchTotal
                )
            } else {
                let filename = itemURL.lastPathComponent
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let progress = device.uploadFile(from: itemURL, toFolderID: newFolderID, storageID: storageID) { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                    transferState = TransferState(
                        id: sessionID,
                        filename: filename,
                        isFolder: false,
                        destinationFolderName: folderName,
                        progress: progress,
                        currentIndex: batchIndex,
                        totalCount: batchTotal
                    )
                }
            }
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
