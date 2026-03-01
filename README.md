# FineTransfer

> **Note:** This is a personal hobby project. For more comprehensive and feature-rich MTP support on macOS, consider using mature alternatives like [OpenMTP](https://github.com/ganeshrvel/openmtp).

A macOS app for transferring files to/from MTP (Media Transfer Protocol) devices such as Android phones, Kindle e-Readers.

![FineTransfer Screenshot](blobs/screenshot.png)

## Requirements

- macOS 26.0 or later
- Xcode 26 or later

## Building

Open `FineTransfer/FineTransfer.xcodeproj` in Xcode. The `MTP.xcodeproj` is referenced as a subproject and will build automatically.

```bash
xcodebuild -project FineTransfer/FineTransfer.xcodeproj -scheme FineTransfer build
```

## Dependencies

- [libmtp](http://libmtp.sourceforge.net/) — MTP protocol implementation (pre-compiled as `libmtp.a`)
- [libusb](https://libusb.info/) — USB access library (pre-compiled as `libusb-1.0.a`)
