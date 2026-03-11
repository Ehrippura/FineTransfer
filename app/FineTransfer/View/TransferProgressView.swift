//
//  TransferProgressView.swift
//  FineTransfer
//

import SwiftUI
import Combine

struct TransferProgressView: View {

    @Binding var state: TransferState?

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
                    Text(state?.filename ?? "")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(state?.destinationFolderName ?? "")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }

                // progress view
                if total > 0 {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                }

                // completed and total
                HStack {
                    Text(formatBytes(completed))
                    Text("/")
                    Text(total > 0 ? formatBytes(total) : "—")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .frame(minWidth: 220)
        .id(state.map { ObjectIdentifier($0.progress) })
        .onReceive(fractionPublisher) {
            fraction = $0
        }
        .onReceive(completedPublisher) {
            completed = $0
        }
        .onReceive(totalPublisher) {
            total = $0
        }
    }

    private var fileIcon: NSImage {
        NSWorkspace.shared.icon(forFilename: state?.filename ?? "", isFolder: state?.isFolder ?? false)
    }

    private var fractionPublisher: AnyPublisher<Double, Never> {
        state?.progress.publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()
    }

    private var completedPublisher: AnyPublisher<Int64, Never> {
        state?.progress.publisher(for: \.completedUnitCount)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()
    }

    private var totalPublisher: AnyPublisher<Int64, Never> {
        state?.progress.publisher(for: \.totalUnitCount)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()
    }

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else {
            return NSLocalizedString("0 bytes", comment: "Zero byte count display")
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview("File") {
    @Previewable @State var state: TransferState? = TransferState(
        id: UUID(),
        filename: "IMG_20260301_142500.jpg",
        isFolder: false,
        destinationFolderName: "Downloads",
        progress: {
            let p = Progress(totalUnitCount: 100_000_000)
            p.completedUnitCount = 42_000_000
            return p
        }(),
        currentIndex: 0,
        totalCount: 1
    )
    return TransferProgressView(state: $state).padding()
}

#Preview("Folder") {
    @Previewable @State var state: TransferState? = TransferState(
        id: UUID(),
        filename: "Projects",
        isFolder: true,
        destinationFolderName: "Backup",
        progress: {
            let p = Progress(totalUnitCount: 100_000_000)
            p.completedUnitCount = 42_000_000
            return p
        }(),
        currentIndex: 0,
        totalCount: 1
    )
    return TransferProgressView(state: $state).padding()
}
