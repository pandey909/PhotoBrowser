# enableDirectClipFlow Usage Guide

## ✅ Feature Implemented

Direct flow: **Thumbnail tap → ZLClipImageViewController** (skip preview/full editor)

---

## 📝 Usage in Your PhotoPickerManager

### Update `configurePhotoSelectionSettings`

```swift
private func configurePhotoSelectionSettings(count: Int, video: Bool, clipRatios: [ZLImageClipRatio]? = nil) {
    let config = ZLPhotoConfiguration.default()
    config.allowSelectImage = true
    config.allowSelectVideo = video
    config.allowSelectGif = false
    config.allowSelectLivePhoto = false
    config.allowSelectOriginal = false
    config.allowEditVideo = true
    config.allowMixSelect = true
    config.maxSelectCount = count
    config.maxEditVideoTime = 60
    config.maxSelectVideoDuration = 60
    config.showPreviewButtonInAlbum = false
    config.allowTakePhotoInLibrary = true
    config.allowPreviewPhotos = false
    config.editAfterSelectThumbnailImage = false
    config.saveNewImageAfterEdit = false  // ✅ Important: Use edited image directly
    
    if let clipRatios {
        let editConfig = ZLEditImageConfiguration()
        editConfig.clipRatios = clipRatios
        config.editImageConfiguration(editConfig)
        
        if count == 1 {
            config.allowEditImage = true
            config.enableDirectClipFlow = true  // ✅ NEW: Direct clip for single select
        } else {
            config.allowEditImage = true
            config.clipSingleImageInMultiselect = true  // For multiselect
        }
    }
}
```

---

## 🎬 What Happens Now

### Single Select with Clip Ratios

```swift
selectSingleMedia(
    from: self, 
    clipRatios: [.circle]
) { result in
    // result.image is the CROPPED image! ✅
    // result.isEdited = true ✅
    print("Cropped image: \(result.image)")
}
```

**Flow:**
```
Thumbnail View
    ↓ User taps image
    ↓ Present modal (fullscreen)
ZLClipImageViewController
    ↓ User crops
    ↓ User taps Done
    ↓ Dismiss
✅ Cropped image returned
```

### Single Select WITHOUT Clip Ratios

```swift
selectSingleMedia(from: self) { result in
    // result.image is the ORIGINAL image
    print("Original image: \(result.image)")
}
```

**Flow:**
```
Thumbnail View
    ↓ User taps image
    ↓ Select (no clip)
✅ Original image returned
```

---

## 🔑 Key Configuration

### For Direct Clip to Work

```swift
// Required:
config.enableDirectClipFlow = true
config.allowEditImage = true
config.maxSelectCount = 1
config.saveNewImageAfterEdit = false  // ✅ Important!

// Set clip ratios:
let editConfig = ZLEditImageConfiguration()
editConfig.clipRatios = [.circle]  // or any ratios
config.editImageConfiguration = editConfig
```

### Why `saveNewImageAfterEdit = false`?

This tells the library to use `model.editImage` directly instead of:
1. Saving edited image to photo album
2. Fetching it back from the album

With `false`:
- ✅ `result.image` = cropped image
- ✅ `result.isEdited` = true
- ✅ Faster (no album save/fetch)

---

## 📋 Complete Example

```swift
func selectSingleMedia(
    from viewController: UIViewController, 
    selected: ZLResultModel? = nil, 
    clipRatios: [ZLImageClipRatio]? = nil, 
    completion: @escaping (ZLResultModel) -> Void
) {
    // Configure photo picker for selecting a single item
    configurePhotoPicker(count: 1, clipRatios: clipRatios)
    
    // Determine selected results based on provided selected model
    let selectedResults: [ZLResultModel] = selected != nil ? [selected!] : []
    
    // Present photo picker and handle selected result
    presentPhotoPicker(from: viewController, selectedResults: selectedResults) { results in
        guard let firstResult = results.first else {
            plog("No result selected.")
            return
        }
        
        // ✅ firstResult.image is CROPPED if clipRatios was provided
        // ✅ firstResult.isEdited = true
        completion(firstResult)
    }
}
```

---

## 🎯 Three Modes Comparison

| Mode | Configuration | maxSelectCount | Opens | Use Case |
|------|--------------|----------------|-------|----------|
| **Direct Clip** (NEW) | `enableDirectClipFlow = true` | 1 | ZLClipImageViewController | Tap → Crop only ✅ |
| **Full Editor** | `editAfterSelectThumbnailImage = true` | 1 | ZLEditImageViewController | Tap → Draw, filters, crop |
| **Multiselect Clip** | `clipSingleImageInMultiselect = true` | > 1 | ZLClipImageViewController | Select 1 → Done → Crop |

---

## ✅ What's Fixed

### Before (Your Issue)
```
User taps image → Crops → Taps Done → ❌ Gets ORIGINAL image
```

### After (With Fix)
```
User taps image → Crops → Taps Done → ✅ Gets CROPPED image
```

**The fix:** `config.saveNewImageAfterEdit = false`

This ensures `model.editImage` (the cropped image) is used directly in the result.

---

## 🚀 Summary

Enable direct clip flow:

```swift
config.enableDirectClipFlow = true
config.saveNewImageAfterEdit = false  // ✅ Critical!
```

Now:
- ✅ Thumbnail tap → Direct to crop
- ✅ Cropped image returned in result
- ✅ `result.isEdited = true`
- ✅ No intermediate screens
- ✅ Minimal code changes
- ✅ No breaking changes (default false)

Perfect! 🎉
