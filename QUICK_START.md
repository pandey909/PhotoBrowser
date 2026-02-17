# Quick Start: Smooth Clip Transition Feature

## Enable the Feature (3 Lines)

```swift
let config = ZLPhotoConfiguration.default()
config.maxSelectCount(4)  // Any number > 1
config.allowEditImage(true)
config.clipSingleImageInMultiselect(true)  // 👈 Enable the feature
```

## Complete Example

```swift
// Configure
let config = ZLPhotoConfiguration.default()
config.allowSelectImage(true)
config.allowSelectVideo(true)
config.allowMixSelect(true)
config.maxSelectCount(4)
config.allowEditImage(true)
config.clipSingleImageInMultiselect(true)  // 👈 New feature

// Create picker
let picker = ZLPhotoPicker(results: selectedResults)
picker.selectImageBlock = { results, isOriginal in
    // If user selected 1 image, it will be cropped
    // If user selected 2+ images, they will be original
    for result in results {
        print("Image: \(result.image)")
        print("Is edited: \(result.isEdited)")
    }
}
picker.showPhotoLibrary(sender: self)
```

## What Happens?

### When User Selects 1 Image:
1. User taps Done
2. Clip controller appears (smooth transition)
3. User crops the image
4. Picker dismisses with cropped image

### When User Selects 2+ Images:
1. User taps Done
2. Picker dismisses with original images (normal flow)

## Customize Clip Ratios (Optional)

```swift
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.custom, .wh1x1, .wh4x3, .wh16x9]
config.editImageConfiguration = editConfig
```

## Available Ratios

- `.custom` - Free-form
- `.circle` - Circular
- `.wh1x1` - Square (1:1)
- `.wh4x3` - Landscape (4:3)
- `.wh16x9` - Widescreen (16:9)
- And more...

## That's It!

No need to manually present `ZLClipImageViewController` anymore. The library handles it automatically with a smooth transition.

## More Details

See `CLIP_SINGLE_IMAGE_MULTISELECT.md` for comprehensive documentation.
