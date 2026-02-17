# Direct Camera Usage with Auto-Clip

## Simple Direct Camera Flow

Open camera → Take photo → Auto-push to clip → Crop → Get cropped image back

**No picker, no thumbnail view, no intermediate screens!**

---

## Complete Code Example

```swift
func openCamera(completion: @escaping (UIImage?) -> Void) {
    guard let rootVC = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow })?
        .rootViewController else {
        print("Cannot find root view controller")
        return
    }

    // Configure clip ratios
    let editConfig = ZLEditImageConfiguration()
    editConfig.clipRatios = [.circle]  // Circular crop
    
    let config = ZLPhotoConfiguration.default()
    _ = config
        .allowEditImage(true)
        .editImageConfiguration(editConfig)
    
    // ✅ Enable auto-clip after taking photo
    config.cameraConfiguration.clipAfterTakingPhoto = true
    
    // ✅ Create camera directly
    let camera = ZLCustomCamera()
    
    camera.takeDoneBlock = { image, url in
        // ✅ Image is already cropped!
        completion(image)
    }
    
    camera.cancelBlock = {
        completion(nil)
    }
    
    // ✅ Must wrap in UINavigationController for push transition
    let nav = UINavigationController(rootViewController: camera)
    nav.modalPresentationStyle = .fullScreen
    rootVC.present(nav, animated: true)
}
```

---

## What Happens (Step by Step)

### 1. Camera Opens
```
┌─────────────────────────────────┐
│        Camera View              │
│                                 │
│  ┌─────────────────────────┐  │
│  │                         │  │
│  │   [Live camera feed]    │  │
│  │                         │  │
│  └─────────────────────────┘  │
│                                 │
│         [Capture] ◄─ User taps │
└─────────────────────────────────┘
```

### 2. Photo Captured → Preview
```
┌─────────────────────────────────┐
│        Preview                  │
│                                 │
│  ┌─────────────────────────┐  │
│  │                         │  │
│  │   [Photo preview]       │  │
│  │                         │  │
│  └─────────────────────────┘  │
│                                 │
│  [Retake]      [Done] ◄─ User  │
└─────────────────────────────────┘
```

### 3. Auto-Push to Clip (Camera Hidden)
```
✅ Camera view hidden
✅ Camera session stopped
✅ Horizontal push animation

┌─────────────────────────────────┐
│    Clip Controller              │
│    (No back button!)            │
│                                 │
│  ┌─────────────────────────┐  │
│  │                         │  │
│  │   [Crop the image]      │  │
│  │                         │  │
│  └─────────────────────────┘  │
│                                 │
│  [Cancel]         [Done]       │
└─────────────────────────────────┘
```

### 4. Done → Get Cropped Image
```
✅ Clip controller pops back (no animation)
✅ Entire camera navigation dismisses
✅ Cropped image returned via takeDoneBlock

┌─────────────────────────────────┐
│        Your App                 │
│                                 │
│  ✅ Cropped image received!    │
│                                 │
└─────────────────────────────────┘
```

---

## Key Features

### ✅ Camera View Hidden
- Camera session stops when pushing to clip
- Camera view hidden (`view.isHidden = true`)
- Only clip controller visible during cropping

### ✅ No Back Button
- Back button hidden in clip controller
- User must tap Done or Cancel
- Clean, focused cropping experience

### ✅ Clean Dismissal
- Pops back to camera (no animation)
- Dismisses entire navigation stack
- Returns to your app cleanly

### ✅ No Intermediate Views
- Direct flow: Camera → Clip → Done
- No ZLEditImageViewController
- No ZLThumbnailViewController
- No ZLPhotoPicker

---

## Configuration Options

### Clip Ratios

```swift
let editConfig = ZLEditImageConfiguration()

// Single ratio
editConfig.clipRatios = [.circle]  // Circular crop only

// Multiple ratios
editConfig.clipRatios = [.wh1x1, .wh4x3]  // Square + 4:3

// Free-form
editConfig.clipRatios = [.custom]  // Free-form crop

config.editImageConfiguration = editConfig
```

### Available Ratios

- `.circle` - Circular crop (perfect for profile pictures)
- `.wh1x1` - Square (1:1)
- `.wh4x3` - Landscape (4:3)
- `.wh16x9` - Widescreen (16:9)
- `.custom` - Free-form cropping

---

## SwiftUI Integration

```swift
struct CameraView: View {
    @State private var showCamera = false
    @State private var croppedImage: UIImage?
    
    var body: some View {
        VStack {
            if let image = croppedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            Button("Open Camera") {
                showCamera = true
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraWrapper { image in
                croppedImage = image
                showCamera = false
            }
        }
    }
}

struct CameraWrapper: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let editConfig = ZLEditImageConfiguration()
        editConfig.clipRatios = [.circle]
        
        let config = ZLPhotoConfiguration.default()
        config.allowEditImage = true
        config.editImageConfiguration = editConfig
        config.cameraConfiguration.clipAfterTakingPhoto = true
        
        let camera = ZLCustomCamera()
        camera.takeDoneBlock = { image, _ in
            completion(image)
        }
        camera.cancelBlock = {
            completion(nil)
        }
        
        let nav = UINavigationController(rootViewController: camera)
        nav.modalPresentationStyle = .fullScreen
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
```

---

## Cancellation

If user taps Cancel during cropping:

```swift
camera.cancelBlock = {
    print("User cancelled")
    completion(nil)
}
```

- Clip controller pops back
- Entire camera dismisses
- `cancelBlock` is called
- No image returned

---

## Videos

This feature **only applies to photos**:

- If user records a video → Normal flow (no clip)
- Video URL returned via `takeDoneBlock`

```swift
camera.takeDoneBlock = { image, url in
    if let image = image {
        // Photo (cropped if feature enabled)
        handleCroppedImage(image)
    } else if let url = url {
        // Video (not cropped)
        handleVideo(url)
    }
}
```

---

## Important: Navigation Controller Required

You **must** wrap the camera in a `UINavigationController`:

```swift
// ✅ Correct
let nav = UINavigationController(rootViewController: camera)
rootVC.present(nav, animated: true)

// ❌ Wrong - push won't work
rootVC.present(camera, animated: true)
```

Without navigation controller, the clip controller cannot be pushed.

---

## Comparison: With vs Without Feature

### Without Feature (Default)
```
Camera → Take photo → Done → Dismiss → Get original image
```

### With Feature Enabled
```
Camera → Take photo → Done → Push to Clip → Crop → Done → Dismiss → Get cropped image
```

---

## Summary

Enable direct camera with auto-clip:

```swift
config.cameraConfiguration.clipAfterTakingPhoto = true
```

Then use:

```swift
let camera = ZLCustomCamera()
camera.takeDoneBlock = { image, _ in
    // Image is already cropped! ✅
}

let nav = UINavigationController(rootViewController: camera)
present(nav, animated: true)
```

Perfect for apps that need:
- Profile picture uploads
- Document scanning with crop
- Product photos with specific aspect ratios
- Any scenario requiring cropped camera photos

Clean, simple, direct! 🎉
