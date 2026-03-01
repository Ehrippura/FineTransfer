//
//  FileGridView.swift
//  FineTransfer
//
//  Created by Wayne Lin on 2026/3/1.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - FileGridView (NSViewRepresentable)

struct FileGridView: NSViewRepresentable {

    var files: [MTPFileItem]
    fileprivate var onItemDoubleClick: ((MTPFileItem) -> Void)?

    init(files: [MTPFileItem]) {
        self.files = files
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(files: files, onItemDoubleClick: onItemDoubleClick)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 100, height: 120)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let collectionView = NSCollectionView()
        collectionView.collectionViewLayout = layout
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        collectionView.register(
            FileCollectionViewItem.self,
            forItemWithIdentifier: FileCollectionViewItem.identifier
        )

        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
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
}

// MARK: - Coordinator

extension FileGridView {

    class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {

        var files: [MTPFileItem]
        var onItemDoubleClick: ((MTPFileItem) -> Void)?
        weak var collectionView: NSCollectionView?

        init(files: [MTPFileItem], onItemDoubleClick: ((MTPFileItem) -> Void)?) {
            self.files = files
            self.onItemDoubleClick = onItemDoubleClick
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

        // MARK: Double Click

        @objc func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
            guard let collectionView = collectionView else { return }
            let point = sender.location(in: collectionView)
            guard let indexPath = collectionView.indexPathForItem(at: point),
                  indexPath.item < files.count else { return }
            let file = files[indexPath.item]
            onItemDoubleClick?(file)
        }
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

        if file.isFolder {
            iconView.image = NSWorkspace.shared.icon(for: .folder)
        } else {
            let ext = (file.filename as? NSString)?.pathExtension ?? ""
            if let utType = UTType(filenameExtension: ext) {
                iconView.image = NSWorkspace.shared.icon(for: utType)
            } else {
                iconView.image = NSWorkspace.shared.icon(for: .data)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FileGridView(files: [])
}
