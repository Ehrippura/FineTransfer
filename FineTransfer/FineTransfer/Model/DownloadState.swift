//
//  DownloadState.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/3/1.
//

import Foundation

struct DownloadState: Identifiable {
    let id: UUID
    let filename: String
    let isFolder: Bool
    let destinationFolderName: String
    let progress: Progress
    let currentIndex: Int
    let totalCount: Int
}
