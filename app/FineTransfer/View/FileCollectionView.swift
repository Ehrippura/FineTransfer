//
//  FileCollectionView.swift
//  FineTransfer
//

import AppKit

class FileCollectionView: NSCollectionView {

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

    // MARK: - Drag Destination

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else {
            return []
        }
        showDropHighlight(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        showDropHighlight(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        showDropHighlight(false)
        let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        guard !urls.isEmpty else {
            return false
        }
        coordinator?.onDropUpload?(urls)
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        showDropHighlight(false)
    }

    private func showDropHighlight(_ on: Bool) {
        wantsLayer = true
        layer?.borderColor = on ? NSColor.controlAccentColor.cgColor : NSColor.clear.cgColor
        layer?.borderWidth = on ? 2 : 0
        layer?.cornerRadius = on ? 6 : 0
    }
}
