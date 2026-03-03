//
//  FileView.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

struct FileView: View {

    var device: MTPDevice?

    @State private var viewModel = FileViewModel()

    init(device: MTPDevice?) {
        self.device = device
    }

    var body: some View {
        FileGridView(files: viewModel.files)
            .onDoubleClick { item in
                if item.isFolder {
                    viewModel.navigateToFolder(item)
                }
            }
            .onDownload { filesToDownload, destination, handler in
                if let destination {
                    let pairs = filesToDownload.map { (file: $0, destination: destination) }
                    Task {
                        do {
                            try await viewModel.downloadFiles(pairs)
                            handler?(nil)
                        } catch {
                            handler?(error)
                        }
                    }
                } else {
                    viewModel.downloadFiles(filesToDownload)
                }
            }
            .onUpload {
                viewModel.uploadFiles()
            }
            .onDropUpload { urls in
                viewModel.uploadFiles(urls: urls)
            }
            .onNewFolder {
                viewModel.createFolder()
            }
            .onRename { file in
                viewModel.renameFile(file)
            }
            .onDelete { filesToDelete in
                viewModel.deleteFiles(filesToDelete)
            }
            .navigationTitle(viewModel.currentFolderName.isEmpty ? "Root" : viewModel.currentFolderName)
            .onAppear {
                viewModel.setDevice(device)
            }
            .onChange(of: device) {
                viewModel.setDevice(device)
            }
            .sheet(item: $viewModel.transferState) { _ in
                TransferProgressView(state: $viewModel.transferState)
                    .interactiveDismissDisabled(true)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: viewModel.goBack) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(viewModel.backStack.isEmpty)

                    Button(action: viewModel.goForward) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(viewModel.forwardStack.isEmpty)
                }

                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .sharedBackgroundVisibility(.hidden)

                if let device, device.storages.count > 1 {
                    ToolbarItem(placement: .primaryAction) {
                        Picker(
                            "Storage",
                            selection: Binding(
                                get: { viewModel.currentStorage },
                                set: { newStorage in
                                    guard newStorage?.storageID != viewModel.currentStorage?.storageID else {
                                        return
                                    }
                                    viewModel.currentStorage = newStorage
                                    viewModel.loadFiles(resetNavigation: true)
                                }
                            )
                        ) {
                            ForEach(device.storages, id: \.storageID) { storage in
                                HStack {
                                    Image(systemName: "externaldrive")
                                    Text(storage.storageDescription ?? "Storage \(storage.storageID)")
                                }
                                .tag(Optional(storage))
                            }
                        }
                        .pickerStyle(.menu)
                        .fixedSize()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.uploadFiles) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .ignoresSafeArea(edges: .all)
    }
}

#Preview {
    FileView(device: nil)
}
