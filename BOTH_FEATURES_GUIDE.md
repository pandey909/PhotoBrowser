# Complete Guide: Both Clip Features

## Two Smooth Clip Features Available

### Feature 1: Picker Clip (Multiselect Mode)
### Feature 2: Camera Clip

---

## Quick Setup (Both Features)

```swift
let config = ZLPhotoConfiguration.default()

// 1. Configure clip ratios (shared by both features)
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.wh1x1]  // Square crop
config.editImageConfiguration = editConfig

// 2. Enable picker clip feature
config.maxSelectCount(4)
config.allowEditImage(true)
config.clipSingleImageInMultiselect = true  // ✅ Feature 1

// 3. Enable camera clip feature
config.cameraConfiguration.clipAfterTakingPhoto = true  // ✅ Feature 2
```

---

## Feature Comparison

| Aspect | Picker Clip | Camera Clip |
|--------|-------------|-------------|
| **Configuration** | `clipSingleImageInMultiselect` | `clipAfterTakingPhoto` |
| **Trigger** | Select 1 image + Done | Take photo + Done |
| **Condition** | maxSelectCount > 1 | Taking photos (not videos) |
| **Animation** | Horizontal push | Horizontal push |
| **Dismissal** | Entire picker | Entire camera |
| **Result** | Cropped image | Cropped image |
| **Ratios** | `editImageConfiguration.clipRatios` | `editImageConfiguration.clipRatios` |

---

## Visual Flow Comparison

### Feature 1: Picker Clip

```
┌─────────────────────────────────────────┐
│          Photo Gallery                  │
│                                         │
│  ┌─────┐  ┌─────┐  ┌─────┐            │
│  │  ✓  │  │     │  │     │            │
│  │ IMG │  │ IMG │  │ IMG │            │
│  └─────┘  └─────┘  └─────┘            │
│                                         │
│                        [Done] ◄─ User  │
└─────────────────────────────────────────┘
                │
                │ Push horizontally ✅
                ▼
┌─────────────────────────────────────────┐
│          Clip Controller                │
│                                         │
│  ┌───────────────────────────────┐    │
│  │                               │    │
│  │      [Crop the image]         │    │
│  │                               │    │
│  └───────────────────────────────┘    │
│                                         │
│  [Cancel]                  [Done]      │
└─────────────────────────────────────────┘
                │
                │ Dismiss entire picker
                ▼
┌─────────────────────────────────────────┐
│          Your App                       │
│                                         │
│  ✅ Cropped image received!            │
└─────────────────────────────────────────┘
```

### Feature 2: Camera Clip

```
┌─────────────────────────────────────────┐
│          Camera View                    │
│                                         │
│  ┌───────────────────────────────┐    │
│  │                               │    │
│  │      [Live camera feed]       │    │
│  │                               │    │
│  └───────────────────────────────┘    │
│                                         │
│              [Capture] ◄─ User taps    │
└─────────────────────────────────────────┘
                │
                │ Photo captured
                ▼
┌─────────────────────────────────────────┐
│          Preview                        │
│                                         │
│  ┌───────────────────────────────┐    │
│  │                               │    │
│  │      [Photo preview]          │    │
│  │                               │    │
│  └───────────────────────────────┘    │
│                                         │
│  [Retake]                  [Done] ◄─ User
└─────────────────────────────────────────┘
                │
                │ Push horizontally ✅
                ▼
┌─────────────────────────────────────────┐
│          Clip Controller                │
│                                         │
│  ┌───────────────────────────────┐    │
│  │                               │    │
│  │      [Crop the image]         │    │
│  │                               │    │
│  └───────────────────────────────┘    │
│                                         │
│  [Cancel]                  [Done]      │
└─────────────────────────────────────────┘
                │
                │ Dismiss entire camera
                ▼
┌─────────────────────────────────────────┐
│          Your App                       │
│                                         │
│  ✅ Cropped image received!            │
└─────────────────────────────────────────┘
```

---

## When Each Feature Activates

### Picker Clip ✅ Activates When:
- `clipSingleImageInMultiselect = true`
- `allowEditImage = true`
- `maxSelectCount > 1`
- User selects **exactly 1 image** (not video)
- User taps **Done**

### Picker Clip ❌ Does NOT Activate When:
- User selects 2+ images
- User selects a video
- Feature is disabled
- maxSelectCount = 1 (use `editAfterSelectThumbnailImage` instead)

### Camera Clip ✅ Activates When:
- `clipAfterTakingPhoto = true`
- User takes a **photo** (not video)
- User taps **Done** in preview

### Camera Clip ❌ Does NOT Activate When:
- User records a video
- Feature is disabled
- User taps Retake

---

## Complete Code Example

```swift
import UIKit

class PhotoManager {
    func selectPhoto(
        video: Bool,
        selectedResults: [ZLResultModel],
        rootVC: UIViewController,
        completion: @escaping ([ZLResultModel]) -> Void
    ) {
        let config = ZLPhotoConfiguration.default()
        
        // Configure clip ratios (used by both features)
        let editConfig = ZLEditImageConfiguration()
        editConfig.clipRatios = [.wh1x1]  // Square crop only
        config.editImageConfiguration = editConfig
        
        // Configure picker
        _ = config
            .allowSelectImage(true)
            .allowSelectVideo(video)
            .allowEditImage(true)
            .allowMixSelect(true)
            .maxSelectCount(4)
            .clipSingleImageInMultiselect(true)  // ✅ Picker clip
        
        // Configure camera
        config.cameraConfiguration.clipAfterTakingPhoto = true  // ✅ Camera clip
        
        // Create picker
        let picker = ZLPhotoPicker(results: selectedResults)
        
        picker.selectImageBlock = { results, _ in
            // Results are already cropped if applicable! ✅
            completion(results)
        }
        
        picker.cancelBlock = {
            print("User cancelled")
        }
        
        picker.showPhotoLibrary(sender: rootVC)
    }
}
```

---

## Clip Ratios Configuration

Both features share the same clip ratios configuration:

```swift
let editConfig = ZLEditImageConfiguration()

// Single ratio
editConfig.clipRatios = [.wh1x1]  // Square only

// Multiple ratios (user can switch)
editConfig.clipRatios = [.wh1x1, .wh4x3, .wh16x9]

// Free-form + specific ratios
editConfig.clipRatios = [.custom, .wh1x1, .wh4x3]

// Circular crop
editConfig.clipRatios = [.circle]

config.editImageConfiguration = editConfig
```

### Available Ratios

| Ratio | Description | Value |
|-------|-------------|-------|
| `.custom` | Free-form cropping | 0 |
| `.circle` | Circular crop | 1 (circle) |
| `.wh1x1` | Square | 1:1 |
| `.wh3x4` | Portrait | 3:4 |
| `.wh4x3` | Landscape | 4:3 |
| `.wh2x3` | Portrait | 2:3 |
| `.wh3x2` | Landscape | 3:2 |
| `.wh9x16` | Portrait | 9:16 |
| `.wh16x9` | Widescreen | 16:9 |

---

## Cancellation Behavior

### Picker Clip Cancellation
- User cancels during crop
- Entire picker dismisses
- `cancelBlock` is called
- No images returned

### Camera Clip Cancellation
- User cancels during crop
- Entire camera dismisses
- `cancelBlock` is called
- No image returned

---

## Video Handling

Both features **only apply to images**, not videos:

### Picker
- If user selects 1 video → Normal flow (no clip)
- If user selects 1 image + videos → Normal flow (no clip)

### Camera
- If user records a video → Normal flow (no clip)
- Video URL returned via `takeDoneBlock`

---

## Benefits of Using Both Features

1. **Consistent UX**: Same smooth transition for picker and camera
2. **Less Code**: No manual clip presentation needed
3. **Configurable**: Enable/disable each independently
4. **Flexible**: Use any clip ratios for both
5. **Professional**: Native-feeling horizontal push transitions

---

## Testing Both Features

### Test Picker Clip:
1. Enable `clipSingleImageInMultiselect = true`
2. Open photo library
3. Select exactly 1 image
4. Tap Done
5. ✅ Should see horizontal push to crop screen

### Test Camera Clip:
1. Enable `clipAfterTakingPhoto = true`
2. Open camera from library
3. Take a photo
4. Tap Done in preview
5. ✅ Should see horizontal push to crop screen

### Test Normal Flows:
1. Select 2+ images → ✅ Should dismiss normally (no crop)
2. Record a video → ✅ Should dismiss normally (no crop)

---

## Summary

Enable both features for complete automatic cropping:

```swift
// One-time configuration
config.clipSingleImageInMultiselect = true  // Picker
config.cameraConfiguration.clipAfterTakingPhoto = true  // Camera

// Set your preferred clip ratios
editConfig.clipRatios = [.wh1x1]
config.editImageConfiguration = editConfig
```

Now your app automatically provides smooth cropping for:
- ✅ Single image selections from gallery
- ✅ Photos taken with camera
- ✅ Both with the same smooth horizontal push transition

Perfect! 🎉
