# Flow Diagram: Smooth Clip Transition

## Problem (Before)

```
┌─────────────────┐
│   Photo Picker  │
│                 │
│  [✓] Image 1    │
│  [ ] Image 2    │
│  [ ] Image 3    │
│                 │
│    [Done] ◄─────┼─── User taps Done
└─────────────────┘
        │
        │ Dismiss (animated)
        ▼
┌─────────────────┐
│   Root View     │  ◄─── Jarring transition!
│                 │       Picker dismisses first
└─────────────────┘
        │
        │ Present (animated)
        ▼
┌─────────────────┐
│ Clip Controller │
│                 │
│   [Crop Image]  │
│                 │
└─────────────────┘
```

## Solution (After)

```
┌─────────────────┐
│   Photo Picker  │
│                 │
│  [✓] Image 1    │
│  [ ] Image 2    │
│  [ ] Image 3    │
│                 │
│    [Done] ◄─────┼─── User taps Done
└─────────────────┘
        │
        │ Push (horizontal slide) - NO DISMISS!
        ▼
┌─────────────────┐
│ Clip Controller │  ◄─── Smooth transition!
│                 │       Pushed onto navigation stack
│   [Crop Image]  │       (no modal animation)
│                 │
└─────────────────┘
        │
        │ Crop complete
        ▼
┌─────────────────┐
│   Root View     │  ◄─── Single dismiss
│                 │       with cropped image
│  [Cropped ✓]   │
└─────────────────┘
```

## Code Flow

### Entry Point: `ZLPhotoPicker.requestSelectPhoto()`

```
┌──────────────────────────────────────────────────┐
│ requestSelectPhoto(models, isSelectOriginal, vc) │
└──────────────────────────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Check conditions:     │
        │ • clipSingleImage...  │
        │ • allowEditImage      │
        │ • maxSelectCount > 1  │
        │ • count == 1          │
        │ • type == .image      │
        └───────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
       YES                     NO
        │                       │
        ▼                       ▼
┌────────────────────┐  ┌──────────────────┐
│ presentClipFor...  │  │ Normal flow      │
│                    │  │ (fetch & dismiss)│
└────────────────────┘  └──────────────────┘
```

### Clip Flow: `presentClipForSingleSelection()`

```
┌──────────────────────────────────────┐
│ presentClipForSingleSelection()      │
└──────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ Show HUD (loading)                   │
└──────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ Fetch image (ZLFetchImageOperation)  │
└──────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ Hide HUD                             │
└──────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────┐
│ Push ZLClipImageViewController       │
│ ONTO: navigation stack (horizontal)  │
│ NO modal animation from bottom       │
└──────────────────────────────────────┘
            │
    ┌───────┴───────┐
    │               │
  Done          Cancel
    │               │
    ▼               ▼
┌────────┐    ┌──────────┐
│ Create │    │ Dismiss  │
│ Result │    │ & call   │
│ with   │    │ cancel   │
│ cropped│    │ block    │
│ image  │    └──────────┘
└────────┘
    │
    ▼
┌──────────────────┐
│ Dismiss picker   │
│ & call select    │
│ block with result│
└──────────────────┘
```

## Condition Matrix

| maxSelectCount | Selected | Type  | clipSingleImage... | Result              |
|----------------|----------|-------|--------------------|---------------------|
| > 1            | 1        | Image | true               | ✅ Show clip        |
| > 1            | 1        | Image | false              | ❌ Normal flow      |
| > 1            | 1        | Video | true               | ❌ Normal flow      |
| > 1            | 2+       | Any   | true               | ❌ Normal flow      |
| 1              | 1        | Image | true               | ❌ Use existing*    |

\* For single select mode (maxSelectCount == 1), use `editAfterSelectThumbnailImage` instead.

## Key Benefits

1. **Smooth Transition**: Horizontal push animation (no modal from bottom)
2. **No Intermediate Dismissal**: Picker stays open until cropping is complete
3. **Better UX**: User stays in navigation context
4. **Less Code**: No manual clip presentation needed
5. **Configurable**: Easy to enable/disable
6. **Backward Compatible**: Opt-in feature

## Implementation Highlights

- **Location**: `ZLPhotoPicker.swift` lines 248-419
- **Configuration**: `ZLPhotoConfiguration.clipSingleImageInMultiselect`
- **Chaining**: `config.clipSingleImageInMultiselect(true)`
- **Clip Ratios**: Uses `editImageConfiguration.clipRatios`
- **Result**: `isEdited = true` for cropped images
