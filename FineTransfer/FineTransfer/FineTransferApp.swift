//
//  FineTransferApp.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import SwiftUI

@main
struct FineTransferApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        Window("Fine Transfer", id: "main") {
            MainView()
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        sender == NSApp
    }
}
