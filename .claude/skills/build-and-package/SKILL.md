---
name: build-and-package
description: This skill builds an Xcode project and packages it as a DMG file.
---

## Triggers

- "build dmg"
- "create dmg"
- "package dmg"
- "build and package"
- "archive and create dmg"

## Instructions

### Step 1: Archive the Xcode Project

Build and archive the project using xcodebuild:

```bash
xcodebuild archive -project <ProjectPath> -scheme <SchemeName> -configuration Release -archivePath ./archive
```

**Parameters:**
- `<ProjectPath>`: Path to the .xcodeproj file (e.g., `FineTransfer/FineTransfer.xcodeproj`)
- `<SchemeName>`: The scheme to build (e.g., `FineTransfer`)

### Step 2: Create DMG (if build succeeds)

Check the exit code and create a DMG file:

```bash
if [ "$?" = "0" ]; then
    hdiutil create -volname <AppName> -srcfolder archive.xcarchive/Products/Applications -ov -format UDZO <AppName>.dmg
    rm -r archive.xcarchive
fi
```

**Parameters:**
- `<AppName>`: The name for the DMG volume and output file (e.g., `FineTransfer`)

### Complete Example

For the FineTransfer project:

```bash
xcodebuild archive -project FineTransfer/FineTransfer.xcodeproj -scheme FineTransfer -configuration Release -archivePath ./archive

if [ "$?" = "0" ]; then
    hdiutil create -volname FineTransfer -srcfolder archive.xcarchive/Products/Applications -ov -format UDZO FineTransfer.dmg
    rm -r archive.xcarchive
fi
```

## Notes

- The build uses the **Release** configuration for optimized production builds
- The `-ov` flag overwrites existing DMG files
- The `-format UDZO` creates a compressed DMG file
- The archive folder is automatically cleaned up after DMG creation
- Always check the xcodebuild exit code before creating the DMG
