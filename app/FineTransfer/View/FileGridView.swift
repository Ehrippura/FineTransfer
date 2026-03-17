//
//  FileGridView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/3/1.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - FileGridView (NSViewRepresentable)

struct FileGridView: NSViewRepresentable {

    var files: [MTPFileItem]
    fileprivate var onItemDoubleClick: ((MTPFileItem) -> Void)?
    fileprivate var onDownload: (([MTPFileItem], URL?, (((any Error)?) -> Void)?) -> Void)?
    fileprivate var onDelete: (([MTPFileItem]) -> Void)?
    fileprivate var onUpload: (() -> Void)?
    fileprivate var onDropUpload: (([URL]) -> Void)?
    fileprivate var onNewFolder: (() -> Void)?
    fileprivate var onRename: ((MTPFileItem) -> Void)?

    init(files: [MTPFileItem]) {
        self.files = files.sorted { lhs, rhs in
            if lhs.isFolder != rhs.isFolder {
                return lhs.isFolder
            }
            return (lhs.filename ?? "").localizedStandardCompare(rhs.filename ?? "") == .orderedAscending
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(files: files, onItemDoubleClick: onItemDoubleClick, onDownload: onDownload, onDelete: onDelete, onUpload: onUpload, onDropUpload: onDropUpload, onNewFolder: onNewFolder, onRename: onRename)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 110, height: 110)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let collectionView = FileCollectionView()
        collectionView.collectionViewLayout = layout
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        collectionView.register(
            FileCollectionViewItem.self,
            forItemWithIdentifier: FileCollectionViewItem.identifier
        )

        collectionView.registerForDraggedTypes([.fileURL])
        collectionView.setDraggingSourceOperationMask([.copy], forLocal: false)
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.coordinator = context.coordinator
        context.coordinator.collectionView = collectionView

        let doubleClickGesture = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleClick(_:))
        )
        doubleClickGesture.numberOfClicksRequired = 2
        doubleClickGesture.delaysPrimaryMouseButtonEvents = false
        collectionView.addGestureRecognizer(doubleClickGesture)

        let scrollView = NSScrollView()
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.automaticallyAdjustsContentInsets = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.files = files
        context.coordinator.onItemDoubleClick = onItemDoubleClick
        context.coordinator.onDownload = onDownload
        context.coordinator.onDelete = onDelete
        context.coordinator.onUpload = onUpload
        context.coordinator.onDropUpload = onDropUpload
        context.coordinator.onNewFolder = onNewFolder
        context.coordinator.onRename = onRename
        if let collectionView = scrollView.documentView as? NSCollectionView {
            collectionView.reloadData()
        }
    }
}

// MARK: - Modifiers

extension FileGridView {

    func onDoubleClick(perform action: @escaping (MTPFileItem) -> Void) -> FileGridView {
        var copy = self
        copy.onItemDoubleClick = action
        return copy
    }

    func onDownload(perform action: @escaping ([MTPFileItem], URL?, (((any Error)?) -> Void)?) -> Void) -> FileGridView {
        var copy = self
        copy.onDownload = action
        return copy
    }

    func onDelete(perform action: @escaping ([MTPFileItem]) -> Void) -> FileGridView {
        var copy = self
        copy.onDelete = action
        return copy
    }

    func onUpload(perform action: @escaping () -> Void) -> FileGridView {
        var copy = self
        copy.onUpload = action
        return copy
    }

    func onDropUpload(perform action: @escaping ([URL]) -> Void) -> FileGridView {
        var copy = self
        copy.onDropUpload = action
        return copy
    }

    func onNewFolder(perform action: @escaping () -> Void) -> FileGridView {
        var copy = self
        copy.onNewFolder = action
        return copy
    }

    func onRename(perform action: @escaping (MTPFileItem) -> Void) -> FileGridView {
        var copy = self
        copy.onRename = action
        return copy
    }
}

// MARK: - Coordinator

extension FileGridView {

    @MainActor
    class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, NSFilePromiseProviderDelegate {

        var files: [MTPFileItem]
        var onItemDoubleClick: ((MTPFileItem) -> Void)?
        var onDownload: (([MTPFileItem], URL?, (((any Error)?) -> Void)?) -> Void)?
        var onDelete: (([MTPFileItem]) -> Void)?
        var onUpload: (() -> Void)?
        var onDropUpload: (([URL]) -> Void)?
        var onNewFolder: (() -> Void)?
        var onRename: ((MTPFileItem) -> Void)?
        fileprivate weak var collectionView: FileCollectionView?

        init(
            files: [MTPFileItem],
            onItemDoubleClick: ((MTPFileItem) -> Void)?,
            onDownload: (([MTPFileItem], URL?, (((any Error)?) -> Void)?) -> Void)?,
            onDelete: (([MTPFileItem]) -> Void)?,
            onUpload: (() -> Void)?,
            onDropUpload: (([URL]) -> Void)?,
            onNewFolder: (() -> Void)?,
            onRename: ((MTPFileItem) -> Void)?
        ) {
            self.files = files
            self.onItemDoubleClick = onItemDoubleClick
            self.onDownload = onDownload
            self.onDelete = onDelete
            self.onUpload = onUpload
            self.onDropUpload = onDropUpload
            self.onNewFolder = onNewFolder
            self.onRename = onRename
        }

        // MARK: NSCollectionViewDataSource

        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            files.count
        }

        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(
                withIdentifier: FileCollectionViewItem.identifier,
                for: indexPath
            ) as! FileCollectionViewItem
            let file = files[indexPath.item]
            item.configure(with: file)
            return item
        }

        // MARK: Context Menu

        private var menuTargetFiles: [MTPFileItem] = []

        func buildContextMenu() -> NSMenu? {
            guard let collectionView else {
                return nil
            }

            let items = collectionView.selectionIndexPaths.compactMap { ip -> MTPFileItem? in
                guard ip.item < files.count else {
                    return nil
                }
                return files[ip.item]
            }

            guard !items.isEmpty else {
                return nil
            }

            menuTargetFiles = items

            let menu = NSMenu()
            let downloadItem = NSMenuItem(
                title: NSLocalizedString("Download", comment: "Context menu: download selected items"),
                action: #selector(downloadMenuItemClicked),
                keyEquivalent: ""
            )
            downloadItem.target = self
            downloadItem.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil)
            menu.addItem(downloadItem)

            if items.count == 1 {
                let renameItem = NSMenuItem(
                    title: NSLocalizedString("Rename", comment: "Context menu: rename selected item"),
                    action: #selector(renameMenuItemClicked),
                    keyEquivalent: ""
                )
                renameItem.target = self
                renameItem.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
                menu.addItem(renameItem)
            }

            if onDelete != nil {
                menu.addItem(.separator())
                let deleteItem = NSMenuItem(
                    title: NSLocalizedString("Delete", comment: "Context menu: delete selected items"),
                    action: #selector(deleteMenuItemClicked),
                    keyEquivalent: ""
                )
                deleteItem.target = self
                deleteItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)?.withSymbolConfiguration(.init(hierarchicalColor: .red))
                menu.addItem(deleteItem)
            }

            return menu
        }

        @objc private func downloadMenuItemClicked() {
            onDownload?(menuTargetFiles, nil, nil)
        }

        @objc private func renameMenuItemClicked() {
            guard let file = menuTargetFiles.first else {
                return
            }
            onRename?(file)
        }

        @objc private func deleteMenuItemClicked() {
            onDelete?(menuTargetFiles)
        }

        func buildEmptySpaceContextMenu() -> NSMenu? {
            guard onUpload != nil || onNewFolder != nil else {
                return nil
            }
            let menu = NSMenu()
            if onNewFolder != nil {
                let newFolderItem = NSMenuItem(
                    title: NSLocalizedString("New Folder", comment: "Context menu: create a new folder on the device"),
                    action: #selector(newFolderMenuItemClicked),
                    keyEquivalent: ""
                )
                newFolderItem.image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil)
                newFolderItem.target = self
                menu.addItem(newFolderItem)
            }
            if onUpload != nil {
                if !menu.items.isEmpty {
                    menu.addItem(.separator())
                }
                let uploadItem = NSMenuItem(
                    title: NSLocalizedString("Upload", comment: "Context menu: upload files to current folder"),
                    action: #selector(uploadMenuItemClicked),
                    keyEquivalent: ""
                )
                uploadItem.target = self
                uploadItem.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
                menu.addItem(uploadItem)
            }
            return menu
        }

        @objc private func uploadMenuItemClicked() {
            onUpload?()
        }

        @objc private func newFolderMenuItemClicked() {
            onNewFolder?()
        }

        // MARK: Double Click

        @objc func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
            guard let collectionView = collectionView else {
                return
            }
            let point = sender.location(in: collectionView)
            guard let indexPath = collectionView.indexPathForItem(at: point),
                  indexPath.item < files.count else {
                return
            }
            let file = files[indexPath.item]
            onItemDoubleClick?(file)
        }

        // MARK: Drag Source

        func collectionView(
            _ collectionView: NSCollectionView,
            pasteboardWriterForItemAt indexPath: IndexPath
        ) -> NSPasteboardWriting? {
            guard indexPath.item < files.count else {
                return nil
            }
            let file = files[indexPath.item]
            return MTPFilePromiseProvider(fileItem: file, delegate: self)
        }

        // MARK: NSFilePromiseProviderDelegate

        func filePromiseProvider(
            _ filePromiseProvider: NSFilePromiseProvider,
            fileNameForType fileType: String
        ) -> String {
            (filePromiseProvider as? MTPFilePromiseProvider)?.fileItem.filename ?? NSLocalizedString("file", comment: "Generic file noun")
        }

        func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping ((any Error)?) -> Void) {

            guard let provider = filePromiseProvider as? MTPFilePromiseProvider else {
                return
            }

            onDownload?([provider.fileItem], url) { error in
                completionHandler(error)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FileGridView(files: [
        .dummyFolder(name: "DCIM"),
        .dummyFolder(name: "Pictures"),
        .dummyFolder(name: "Music"),
        .dummyFolder(name: "System Confiuration"),
        .dummy(filename: "photo.png", filesize: 3_500_000),
        .dummy(filename: "very saxy.mpg", filesize: 3_500_000),
    ])
}
