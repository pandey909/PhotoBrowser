# Clip Single Image in Multiselect Mode

## Overview

This feature provides a smooth transition when users select exactly one image in multiselect mode. Instead of dismissing the picker and then presenting the clip controller from the calling view controller (which creates a jarring transition), the clip controller is now presented directly from the picker's view controller before dismissing.

## Configuration

To enable this feature, set the `clipSingleImageInMultiselect` configuration option:

```swift
let config = ZLPhotoConfiguration.default()
config.allowSelectImage(true)
config.allowSelectVideo(true)
config.allowMixSelect(true)
config.maxSelectCount(4)  // Must be > 1 for this feature to work
config.allowEditImage(true)  // Required for clipping
config.clipSingleImageInMultiselect(true)  // Enable the feature
```

## How It Works

### Conditions

The clip controller will be automatically presented when **ALL** of the following conditions are met:

1. `clipSingleImageInMultiselect` is `true`
2. `allowEditImage` is `true`
3. `maxSelectCount > 1` (multiselect mode)
4. User selects exactly **1** asset
5. The selected asset is an **image** (not a video)
6. User taps the **Done** button

### Behavior

**Before (without this feature):**
```
User selects 1 image → Taps Done → Picker dismisses → App presents clip controller
                                    ↑ Jarring transition
```

**After (with this feature):**
```
User selects 1 image → Taps Done → Clip controller presents from picker → User crops → Picker dismisses with cropped image
                                    ↑ Smooth transition
```

### User Cancellation

If the user cancels the clip operation, the picker will dismiss and the `cancelBlock` will be called (no images will be returned).

## Example Usage

### Basic Example

```swift
let config = ZLPhotoConfiguration.default()
config.allowSelectImage(true)
config.allowSelectVideo(true)
config.allowMixSelect(true)
config.maxSelectCount(4)
config.allowEditImage(true)
config.clipSingleImageInMultiselect(true)

let picker = ZLPhotoPicker(results: selectedResults)
picker.selectImageBlock = { results, isOriginal in
    // If user selected 1 image, results[0] will contain the cropped image
    // If user selected 2+ images, results will contain the original images
    for result in results {
        print("Image: \(result.image)")
        print("Is edited: \(result.isEdited)")  // Will be true for cropped single image
    }
}
picker.cancelBlock = {
    print("User cancelled")
}
picker.showPhotoLibrary(sender: self)
```

### Customizing Clip Ratios

You can customize the available clip ratios through the edit image configuration:

```swift
let config = ZLPhotoConfiguration.default()
config.maxSelectCount(4)
config.allowEditImage(true)
config.clipSingleImageInMultiselect(true)

// Customize clip ratios
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.custom, .wh1x1, .wh4x3, .wh16x9]
config.editImageConfiguration = editConfig

let picker = ZLPhotoPicker()
picker.selectImageBlock = { results, _ in
    // Handle results
}
picker.showPhotoLibrary(sender: self)
```

### Available Clip Ratios

- `.custom` - Free-form cropping
- `.circle` - Circular crop
- `.wh1x1` - Square (1:1)
- `.wh3x4` - Portrait (3:4)
- `.wh4x3` - Landscape (4:3)
- `.wh2x3` - Portrait (2:3)
- `.wh3x2` - Landscape (3:2)
- `.wh9x16` - Portrait (9:16)
- `.wh16x9` - Widescreen (16:9)

## Migration Guide

### If You Were Using Custom Clip Logic

**Before:**
```swift
let picker = ZLPhotoPicker(results: selectedResults)
picker.selectImageBlock = { results, _ in
    if results.count == 1, let first = results.first, first.asset.mediaType == .image {
        // Custom clip logic
        ZLClipImageViewController.present(for: first, from: rootVC, clipRatios: [.wh4x3]) { cropped in
            let model = ZLResultModel(asset: first.asset, image: cropped, isEdited: true, editModel: nil, index: 0)
            completion([model])
        }
    } else {
        completion(results)
    }
}
picker.showPhotoLibrary(sender: rootVC)
```

**After:**
```swift
let config = ZLPhotoConfiguration.default()
config.maxSelectCount(4)
config.allowEditImage(true)
config.clipSingleImageInMultiselect(true)

let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.wh4x3]  // Or any ratios you want
config.editImageConfiguration = editConfig

let picker = ZLPhotoPicker(results: selectedResults)
picker.selectImageBlock = { results, _ in
    // No need for custom clip logic anymore!
    // results[0] will already contain the cropped image if user selected 1 image
    completion(results)
}
picker.showPhotoLibrary(sender: rootVC)
```

## Notes

- This feature only applies to **multiselect mode** (`maxSelectCount > 1`)
- For single select mode (`maxSelectCount == 1`), use the existing `editAfterSelectThumbnailImage` configuration
- The clip controller uses the same ratios configured in `editImageConfiguration.clipRatios`
- The cropped image will have `isEdited = true` in the result model
- Videos are not affected by this feature (only images)

## Implementation Details

The implementation intercepts the selection flow in `ZLPhotoPicker.requestSelectPhoto()` and:

1. Checks if all conditions are met for presenting the clip controller
2. Fetches the selected image
3. Presents `ZLClipImageViewController` from the current picker view controller
4. On completion, creates a `ZLResultModel` with the cropped image and `isEdited = true`
5. Dismisses the picker and calls the `selectImageBlock`
6. On cancellation, dismisses the picker and calls the `cancelBlock`

This ensures a smooth, native-feeling transition without any intermediate dismissals.
