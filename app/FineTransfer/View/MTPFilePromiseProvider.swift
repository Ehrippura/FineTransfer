//
//  MTPFilePromiseProvider.swift
//  FineTransfer
//

import AppKit
import UniformTypeIdentifiers

final class MTPFilePromiseProvider: NSFilePromiseProvider, @unchecked Sendable {

    var fileItem: MTPFileItem!

    convenience init(fileItem: MTPFileItem, delegate: NSFilePromiseProviderDelegate) {
        let fileType: String
        if fileItem.isFolder {
            fileType = UTType.folder.identifier
        } else {
            let ext = ((fileItem.filename ?? "") as NSString).pathExtension
            fileType = (!ext.isEmpty ? UTType(filenameExtension: ext)?.identifier : nil)
                       ?? UTType.data.identifier
        }
        self.init(fileType: fileType, delegate: delegate)
        self.fileItem = fileItem
    }
}
