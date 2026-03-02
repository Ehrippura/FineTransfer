# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FineTransfer** is a macOS app for transferring files to/from MTP (Media Transfer Protocol) devices such as Android phones, cameras, and media players.

**Platform**: Apple Silicon only (arm64 architecture)

## Architecture

The project uses a two-layer approach:

1. **MTP.framework** — A macOS framework that wraps the pre-compiled `libmtp.a` and `libusb-1.0.a` static libraries. It links against `IOKit`, `CoreFoundation`, `Security`, and `libiconv`. `MTP.framework` is embedded into FineTransfer.app at build time.

2. **FineTransfer app** — SwiftUI macOS app. The ObjC layer (`EWFTDeviceManager`) bridges C libmtp calls into Swift via the bridging header. `DeviceManager` is a singleton accessed in Swift as `DeviceManager.shared`.

**Language boundary:**
- `libmtp` C API → called from ObjC (`EWFTDeviceManager.m`) via `#import <MTP/MTP.h>`
- ObjC → Swift via `FineTransfer-Bridging-Header.h` (imports `EWFTDeviceManager.h`)

**Debug behavior:** In DEBUG builds, `EWFTDeviceManager` enables `LIBMTP_DEBUG_PTP` logging.

## MTP document referance

`libmtp/examples` folder contains various examples for libmtp usage.

## Coding Style

### Swift

**Control flow braces**: When using `guard let` for optional unwrapping, `if-else` statements, or closures, do NOT write `{ return }` or other single-statement bodies on the same line. Always use a new line for readability.

```swift
// ❌ Bad - return on same line
guard let device = deviceManager.currentDevice else { return }
if condition { doSomething() }
someFunction { print("done") }

// ✅ Good - return on new line
guard let device = deviceManager.currentDevice else {
    return
}

if condition {
    doSomething()
}

someFunction {
    print("done")
}
```

## Building

Open in Xcode. Build order matters — `MTP.xcodeproj` is referenced as a subproject of `FineTransfer.xcodeproj` and must build first.

**Note**: This project only supports Apple Silicon (arm64). Intel Macs are not supported.

```bash
# Build from command line (macOS target, Apple Silicon)
xcodebuild -project FineTransfer/FineTransfer.xcodeproj -scheme FineTransfer -arch arm64 build
```
