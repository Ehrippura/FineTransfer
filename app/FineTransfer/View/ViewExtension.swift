//
//  ViewExtension.swift
//  FineTransfer
//
//  Created by Tzu-Yi Lin on 2026/3/3.
//

import SwiftUI

extension View {
    func apply(@ViewBuilder content: (Self) -> some View) -> some View {
        content(self)
    }
}

extension ToolbarContent {

    @ToolbarContentBuilder
    func hideGlassBackground() -> some ToolbarContent {
        if #available(macOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
