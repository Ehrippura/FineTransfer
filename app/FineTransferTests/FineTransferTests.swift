//
//  FineTransferTests.swift
//  FineTransferTests
//
//  Created by Tzu-Yi Lin on 2026/2/28.
//

import Testing
@testable import FineTransfer

struct FineTransferTests {

    // MARK: - DeviceManager singleton

    @Test func sharedManagerIsSingleton() {
        let a = DeviceManager.shared
        let b = DeviceManager.shared
        #expect(a === b)
    }
}
