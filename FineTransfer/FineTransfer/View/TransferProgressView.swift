//
//  TransferProgressView.swift
//  FineTransfer
//

import SwiftUI
import Combine

struct TransferProgressView: View {

    let sourceName: String
    let destinationName: String
    let progress: Progress
    var isFolder: Bool = false

    @State private var fraction: Double = 0
    @State private var completed: Int64 = 0
    @State private var total: Int64 = 0

    var body: some View {
        HStack(alignment: .center, spacing: 12) {

            // Icon
            Image(nsImage: fileIcon)
                .resizable()
                .interpolation(.high)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {

                // source and destination
                HStack(spacing: 6) {
                    Text(sourceName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(destinationName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }

                // 2. progress view
                if total > 0 {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                }

                // 3. completed and total
                HStack {
                    Text(formatBytes(completed))
                    Text("/")
                    Text(total > 0 ? formatBytes(total) : "—")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 220)
        .onReceive(progress.publisher(for: \.fractionCompleted).receive(on: RunLoop.main)) {
            fraction = $0
        }
        .onReceive(progress.publisher(for: \.completedUnitCount).receive(on: RunLoop.main)) {
            completed = $0
        }
        .onReceive(progress.publisher(for: \.totalUnitCount).receive(on: RunLoop.main)) {
            total = $0
        }
    }

    private var fileIcon: NSImage {
        NSWorkspace.shared.icon(forFilename: sourceName, isFolder: isFolder)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 bytes" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview("File") {
    let progress = Foundation.Progress(totalUnitCount: 100_000_000)
    progress.completedUnitCount = 42_000_000

    return TransferProgressView(
        sourceName: "IMG_20260301_142500.jpg",
        destinationName: "Downloads",
        progress: progress
    )
    .padding()
}

#Preview("Folder") {
    let progress = Foundation.Progress(totalUnitCount: 100_000_000)
    progress.completedUnitCount = 42_000_000

    return TransferProgressView(
        sourceName: "Projects",
        destinationName: "Backup",
        progress: progress,
        isFolder: true
    )
    .padding()
}
