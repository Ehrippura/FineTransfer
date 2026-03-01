//
//  FileGridView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/3/1.
//

import SwiftUI
import AppKit

// MARK: - FileGridView (NSViewRepresentable)

struct FileGridView: NSViewRepresentable {

    var files: [MTPFileItem]
    fileprivate var onItemDoubleClick: ((MTPFileItem) -> Void)?
    fileprivate var onDownload: (([MTPFileItem]) -> Void)?
    fileprivate var onDelete: (([MTPFileItem]) -> Void)?
    fileprivate var onUpload: (() -> Void)?

    init(files: [MTPFileItem]) {
        self.files = files
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(files: files, onItemDoubleClick: onItemDoubleClick, onDownload: onDownload, onDelete: onDelete, onUpload: onUpload)
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

    func onDownload(perform action: @escaping ([MTPFileItem]) -> Void) -> FileGridView {
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
}

// MARK: - Coordinator

extension FileGridView {

    class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {

        var files: [MTPFileItem]
        var onItemDoubleClick: ((MTPFileItem) -> Void)?
        var onDownload: (([MTPFileItem]) -> Void)?
        var onDelete: (([MTPFileItem]) -> Void)?
        var onUpload: (() -> Void)?
        fileprivate weak var collectionView: FileCollectionView?

        init(files: [MTPFileItem], onItemDoubleClick: ((MTPFileItem) -> Void)?, onDownload: (([MTPFileItem]) -> Void)?, onDelete: (([MTPFileItem]) -> Void)?, onUpload: (() -> Void)?) {
            self.files = files
            self.onItemDoubleClick = onItemDoubleClick
            self.onDownload = onDownload
            self.onDelete = onDelete
            self.onUpload = onUpload
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
            menu.addItem(downloadItem)

            if onDelete != nil {
                menu.addItem(.separator())
                let deleteItem = NSMenuItem(
                    title: NSLocalizedString("Delete", comment: "Context menu: delete selected items"),
                    action: #selector(deleteMenuItemClicked),
                    keyEquivalent: ""
                )
                deleteItem.target = self
                menu.addItem(deleteItem)
            }

            return menu
        }

        @objc private func downloadMenuItemClicked() {
            onDownload?(menuTargetFiles)
        }

        @objc private func deleteMenuItemClicked() {
            onDelete?(menuTargetFiles)
        }

        func buildEmptySpaceContextMenu() -> NSMenu? {
            guard onUpload != nil else {
                return nil
            }
            let menu = NSMenu()
            let uploadItem = NSMenuItem(
                title: NSLocalizedString("Upload", comment: "Context menu: upload files to current folder"),
                action: #selector(uploadMenuItemClicked),
                keyEquivalent: ""
            )
            uploadItem.target = self
            menu.addItem(uploadItem)
            return menu
        }

        @objc private func uploadMenuItemClicked() {
            onUpload?()
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
    }
}

// MARK: - FileCollectionView

private class FileCollectionView: NSCollectionView {

    weak var coordinator: FileGridView.Coordinator?

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        guard let indexPath = indexPathForItem(at: point) else {
            return coordinator?.buildEmptySpaceContextMenu()
        }

        // Right-click on an unselected item: select only that item
        if !selectionIndexPaths.contains(indexPath) {
            selectionIndexPaths = [indexPath]
        }

        return coordinator?.buildContextMenu()
    }
}

// MARK: - FileCollectionViewItem

fileprivate class FileCollectionViewItem: NSCollectionViewItem {

    static let identifier = NSUserInterfaceItemIdentifier("FileCollectionViewItem")

    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.maximumNumberOfLines = 2
        nameLabel.font = .systemFont(ofSize: 12)

        container.addSubview(iconView)
        container.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
        ])

        self.view = container
    }

    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected
                ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.3).cgColor
                : nil
            view.layer?.cornerRadius = isSelected ? 8 : 0
        }
    }

    func configure(with file: MTPFileItem) {
        nameLabel.stringValue = file.filename ?? "Unknown"
        iconView.image = NSWorkspace.shared.icon(forFilename: file.filename ?? "", isFolder: file.isFolder)
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
