# Camera Clip Feature

## Overview

Automatically push to the clip/crop interface after taking a photo with `ZLCustomCamera`. This provides a smooth, seamless transition from camera to cropping without any modal animations.

## Configuration

Enable the feature in your camera configuration:

```swift
let config = ZLPhotoConfiguration.default()

// Enable camera clip feature
config.cameraConfiguration.clipAfterTakingPhoto = true

// Configure clip ratios (optional)
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.wh1x1]  // Square crop only
config.editImageConfiguration = editConfig
```

## Complete Example

```swift
isLoading = true
errorMessage = nil

let config = ZLPhotoConfiguration.default()

// Configure edit settings with clip ratios
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.wh1x1]  // Square crop only

// Apply configuration
_ = config
    .allowSelectImage(true)
    .allowSelectVideo(video)
    .allowEditImage(true)
    .allowMixSelect(true)
    .maxSelectCount(4)
    .clipSingleImageInMultiselect(true)  // For picker
    .editImageConfiguration(editConfig)

// Enable camera clip feature
config.cameraConfiguration.clipAfterTakingPhoto = true

let picker = ZLPhotoPicker(results: selectedResults)
picker.selectImageBlock = { [weak self] results, _ in
    guard let self else { return }
    Task { @MainActor in
        self.isLoading = false
        completion(results)
        self.selectedResults = results
        self.selectedImage = results.first?.image
    }
}

picker.cancelBlock = { [weak self] in
    Task { @MainActor in
        self?.isLoading = false
    }
}

picker.showPhotoLibrary(sender: rootVC)
```

## Or Using Camera Directly

```swift
let config = ZLPhotoConfiguration.default()

// Configure clip ratios
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.wh1x1]
config.editImageConfiguration = editConfig

// Enable camera clip
config.cameraConfiguration.clipAfterTakingPhoto = true

let camera = ZLCustomCamera()
camera.takeDoneBlock = { [weak self] image, url in
    // image is already cropped! ✅
    self?.handleCroppedImage(image)
}

camera.cancelBlock = { [weak self] in
    self?.handleCancel()
}

// Present camera
let nav = UINavigationController(rootViewController: camera)
nav.modalPresentationStyle = .fullScreen
present(nav, animated: true)
```

## How It Works

### Flow

```
┌─────────────────┐
│  Camera View    │
│                 │
│  [Take Photo]   │ ◄── User taps
└─────────────────┘
        │
        │ Photo captured
        ▼
┌─────────────────┐
│  Preview        │
│  [Retake][Done] │ ◄── User taps Done
└─────────────────┘
        │
        │ Push (horizontal slide) - NO DISMISS!
        ▼
┌─────────────────┐
│ Clip Controller │ ✅ Smooth transition
│                 │
│   [Crop Image]  │
│                 │
└─────────────────┘
        │
        │ User crops and taps Done
        ▼
┌─────────────────┐
│   Root View     │
│                 │
│  ✅ Cropped!    │
└─────────────────┘
```

### Conditions

The clip controller will be shown when:

1. `clipAfterTakingPhoto` is `true`
2. User took a **photo** (not a video)
3. User taps the **Done** button

### Behavior

**With Feature Enabled:**
- User takes photo → Taps Done → Clip controller pushes horizontally → User crops → Camera dismisses with cropped image

**With Feature Disabled (Default):**
- User takes photo → Taps Done → Camera dismisses with original image

## Clip Ratios

The clip controller uses the ratios configured in `editImageConfiguration.clipRatios`:

```swift
let editConfig = ZLEditImageConfiguration()

// Single ratio
editConfig.clipRatios = [.wh1x1]  // Square only

// Multiple ratios
editConfig.clipRatios = [.wh1x1, .wh4x3, .wh16x9]  // Square, 4:3, 16:9

// Free-form + ratios
editConfig.clipRatios = [.custom, .wh1x1, .wh4x3]

// Circular crop
editConfig.clipRatios = [.circle]

config.editImageConfiguration = editConfig
```

### Available Ratios

- `.custom` - Free-form cropping
- `.circle` - Circular crop
- `.wh1x1` - Square (1:1)
- `.wh3x4` - Portrait (3:4)
- `.wh4x3` - Landscape (4:3)
- `.wh2x3` - Portrait (2:3)
- `.wh3x2` - Landscape (3:2)
- `.wh9x16` - Portrait (9:16)
- `.wh16x9` - Widescreen (16:9)

## Cancellation

If the user cancels during cropping:
- The entire camera dismisses
- `cancelBlock` is called
- No image is returned

## Videos

This feature **only applies to photos**. When recording a video:
- The clip controller is **not** shown (videos can't be cropped)
- Camera dismisses normally
- Video URL is returned via `takeDoneBlock`

## Implementation Details

### Technical Flow

1. User taps Done button in camera preview
2. `doneBtnClick()` checks if `clipAfterTakingPhoto` is enabled
3. If enabled and it's a photo (not video):
   - Creates `ZLClipImageViewController` with the taken image
   - Pushes it onto the navigation stack (smooth horizontal transition)
   - Sets up `clipDoneBlock` to handle rotation and cropping
   - Sets up `cancelClipBlock` to handle cancellation
4. User crops the image
5. Rotation and cropping applied
6. Entire camera dismisses
7. Cropped image returned via `takeDoneBlock`

### Code Location

- Configuration: `ZLCameraConfiguration.clipAfterTakingPhoto`
- Implementation: `ZLCustomCamera.doneBtnClick()` and `pushToClipController()`

## Benefits

1. **Smooth Transition**: Horizontal push animation (no modal)
2. **Consistent UX**: Same flow as picker clip feature
3. **No Extra Code**: Automatic cropping without manual handling
4. **Configurable**: Easy to enable/disable
5. **Flexible Ratios**: Use any clip ratios you want

## Comparison with Picker Feature

| Feature | Picker Clip | Camera Clip |
|---------|-------------|-------------|
| Configuration | `clipSingleImageInMultiselect` | `clipAfterTakingPhoto` |
| Trigger | Select 1 image, tap Done | Take photo, tap Done |
| Applies To | Selected images | Taken photos |
| Videos | Not affected | Not affected |
| Animation | Push (horizontal) | Push (horizontal) |
| Ratios | `editImageConfiguration.clipRatios` | `editImageConfiguration.clipRatios` |

## Summary

Enable smooth camera-to-crop transition with one line:

```swift
config.cameraConfiguration.clipAfterTakingPhoto = true
```

Perfect for apps that need consistent square or specific aspect ratio images! 🎉
