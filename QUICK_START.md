# Quick Start: Smooth Clip Transition Features

## Two Features Available

### 1. Picker Clip (Multiselect Mode)
Enable automatic clip when selecting 1 image in multiselect mode

### 2. Camera Clip
Enable automatic clip after taking a photo with camera

## Enable Both Features (Complete Setup)

```swift
let config = ZLPhotoConfiguration.default()

// Configure clip ratios
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.wh1x1]  // Square crop only
config.editImageConfiguration = editConfig

// Enable features
config.maxSelectCount(4)  // Any number > 1
config.allowEditImage(true)
config.clipSingleImageInMultiselect(true)  // 👈 Picker clip
config.cameraConfiguration.clipAfterTakingPhoto = true  // 👈 Camera clip
```

## Complete Example (Both Features)

```swift
// Configure
let config = ZLPhotoConfiguration.default()

// Set clip ratios
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.wh1x1]  // Square only
config.editImageConfiguration = editConfig

// Enable both features
config.allowSelectImage(true)
config.allowSelectVideo(true)
config.allowMixSelect(true)
config.maxSelectCount(4)
config.allowEditImage(true)
config.clipSingleImageInMultiselect(true)  // 👈 Picker clip
config.cameraConfiguration.clipAfterTakingPhoto = true  // 👈 Camera clip

// Create picker
let picker = ZLPhotoPicker(results: selectedResults)
picker.selectImageBlock = { results, isOriginal in
    // Images are already cropped! ✅
    // - If selected 1 image from picker: cropped
    // - If took photo with camera: cropped
    // - If selected 2+ images: original
    for result in results {
        print("Image: \(result.image)")
        print("Is edited: \(result.isEdited)")
    }
}
picker.showPhotoLibrary(sender: self)
```

## What Happens?

### Picker: When User Selects 1 Image
1. User taps Done
2. Clip controller pushes horizontally (smooth transition)
3. User crops the image
4. Picker dismisses with cropped image

### Picker: When User Selects 2+ Images
1. User taps Done
2. Picker dismisses with original images (normal flow)

### Camera: When User Takes a Photo
1. User takes photo
2. User taps Done in preview
3. Clip controller pushes horizontally (smooth transition)
4. User crops the image
5. Camera dismisses with cropped image

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

No need to manually present `ZLClipImageViewController` anymore. The library handles it automatically with smooth horizontal push transitions.

## More Details

- **Picker Feature**: See `CLIP_SINGLE_IMAGE_MULTISELECT.md`
- **Camera Feature**: See `CAMERA_CLIP_FEATURE.md`
- **Visual Comparison**: See `VISUAL_COMPARISON.md`
