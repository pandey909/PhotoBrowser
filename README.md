# ZLPhotoBrowser - Local SPM Package

This is a local Swift Package Manager (SPM) copy of ZLPhotoBrowser for use without Git.

## Package Structure

```
LocalZL/
├── Package.swift          # SPM manifest
├── README.md              # This file
└── Sources/
    ├── Animation/         # Transition animations
    ├── Camera/            # Custom camera
    ├── Edit/              # Image & video editing
    ├── Extensions/        # UIKit/Swift extensions
    ├── General/           # Core picker, config, models
    ├── ZLPhotoBrowser.bundle   # Localizations & images
    ├── PrivacyInfo.xcprivacy
    └── ZLPhotoBrowser.h   # ObjC umbrella (optional)
```

## How to Use in Your Xcode Project

### Option 1: Add Local Package (Recommended)

1. In Xcode: **File → Add Package Dependencies...**
2. Click **Add Local...** (bottom left)
3. Navigate to and select: `/Users/swarajmeet/Desktop/LocalZL`
4. Click **Add Package**
5. Select the **ZLPhotoBrowser** library and add it to your target

### Option 2: Drag & Drop

1. Drag the `LocalZL` folder into your Xcode project navigator
2. When prompted, choose **Add to targets** and select your app target
3. Ensure "Add to Project" is selected (not "Copy items if needed" if you want to edit in place)

### Option 3: Swift Package via Path (Xcode 15+)

In **File → Add Package Dependencies**, use:
```
file:///Users/swarajmeet/Desktop/LocalZL
```

## Usage in Code

```swift
import ZLPhotoBrowser

// Preview selection
let picker = ZLPhotoPicker()
picker.selectImageBlock = { results, isOriginal in
    // Handle selected photos/videos
}
picker.showPreview(animate: true, sender: self)

// Or library selection
picker.showPhotoLibrary(sender: self)
```

## Info.plist Keys Required

Add these to your app's Info.plist:

- `Privacy - Photo Library Usage Description`
- `Privacy - Camera Usage Description`
- `Privacy - Microphone Usage Description` (for video recording)
- `Localized resources can be mixed` = `YES` (for multi-language support)

## Notes

- **iOS 10.0+** required
- The package excludes `ZLWeakProxy.h` and `ZLWeakProxy.m` (uses Swift version)
- Edit files in `/Users/swarajmeet/Desktop/LocalZL/Sources` to customize the library
