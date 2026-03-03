//
//  NSWorkspaceExtension.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/3/1.
//


import AppKit
import UniformTypeIdentifiers

extension NSWorkspace {

    /// Returns the system icon for a file or folder, resolved by filename extension.
    func icon(forFilename filename: String, isFolder: Bool) -> NSImage {
        if isFolder {
            return icon(for: .folder)
        }
        let ext = (filename as NSString).pathExtension
        if !ext.isEmpty, let utType = UTType(filenameExtension: ext) {
            return icon(for: utType)
        }
        return icon(for: .data)
    }
}
