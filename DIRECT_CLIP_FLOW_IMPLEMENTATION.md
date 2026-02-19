# Direct Clip Flow – Implementation Guide (SPM)

This guide describes how to add the **direct clip flow** to the PhotoBrowser SPM package with **minimal code changes** and **no breaking changes** to existing behavior. When enabled, tapping a thumbnail in single-selection mode goes directly to **ZLClipImageViewController** (crop screen) instead of **ZLPhotoPreviewController** or **ZLEditImageViewController**.

---

## 1. Overview

- **What:** New config flag `enableDirectClipFlow`. When `true` (and other conditions below), thumbnail tap → load image → present **ZLClipImageViewController** → on done, add model to selection and call Done.
- **Existing behavior:** Unchanged when `enableDirectClipFlow` is `false` (default). Preview, edit-after-select, and multiselect flows stay as they are.
- **Where:** Two files only:
  - `Sources/ZLPhotoBrowser/General/ZLPhotoConfiguration.swift`
  - `Sources/ZLPhotoBrowser/General/ZLThumbnailViewController.swift`

---

## 2. Change 1: ZLPhotoConfiguration – add `enableDirectClipFlow`

**File:** `Sources/ZLPhotoBrowser/General/ZLPhotoConfiguration.swift`

**Where:** Add a new property **after** `editAfterSelectThumbnailImage` and **before** `saveNewImageAfterEdit` (so it sits with the other “edit after select” options).

**Add this block:**

```swift
/// Enable direct clip flow (skip ZLEditImageViewController and go directly to ZLClipImageViewController). Defaults to false.
/// When enabled, tapping a thumbnail in single-selection mode opens the crop screen directly.
/// Only valid when maxSelectCount is 1 and allowEditImage is true.
/// The first ratio from editImageConfiguration.clipRatios will be used as the default.
public var enableDirectClipFlow = false
```

**Exact location:** After the line:

```swift
public var editAfterSelectThumbnailImage = false
```

and before:

```swift
/// Save the edited image to the album after editing. Defaults to true.
public var saveNewImageAfterEdit = true
```

No other edits in this file. Default `false` keeps existing behavior unchanged.

---

## 3. Change 2: ZLThumbnailViewController – direct clip check and three helpers

**File:** `Sources/ZLPhotoBrowser/General/ZLThumbnailViewController.swift`

### 3.1 Insert direct-clip check in `collectionView(_:didSelectItemAt:)`

**Where:** Right after you have the model `m` and the index path is valid, and **before** the existing `shouldDirectEdit(m)` call.

**Current pattern (conceptually):**

```swift
let m = arrDataSources[index]
if shouldDirectEdit(m) {
    return
}
let vc = ZLPhotoPreviewController(...)
```

**Change to:**

```swift
let m = arrDataSources[index]

// Direct clip flow: thumbnail tap → ZLClipImageViewController (before preview/edit)
if shouldDirectClip(m) {
    return
}

if shouldDirectEdit(m) {
    return
}
let vc = ZLPhotoPreviewController(...)
```

So you add **one** call: `if shouldDirectClip(m) { return }` between `let m = arrDataSources[index]` and `if shouldDirectEdit(m)`.

**Exact location:** In `collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)`, after:

```swift
guard arrDataSources.indices ~= index else {
    return
}

let m = arrDataSources[index]
```

Insert:

```swift
// Direct clip: go straight to crop when enabled (single image, allowEditImage, clip ratios set)
if shouldDirectClip(m) {
    return
}
```

Then leave the existing `if shouldDirectEdit(m) { return }` and the rest of the method as-is.

---

### 3.2 Add three private methods

Add these **after** `shouldDirectEdit(_ model: ZLPhotoModel)` and **before** `private func setCellIndex(...)`.

#### 3.2.1 `shouldDirectClip(_ model: ZLPhotoModel) -> Bool`

- Returns `true` only when direct clip should run; then it calls `showDirectClipVC(model)` and returns `true`.
- Conditions (all required):
  - `config.enableDirectClipFlow == true`
  - `config.allowEditImage == true`
  - `config.maxSelectCount == 1`
  - Model is image (e.g. `model.type.rawValue < ZLPhotoModel.MediaType.video.rawValue`)
  - Selection state: either nothing selected, or the only selected model is this one (same as `shouldDirectEdit`).

**Code to add:**

```swift
private func shouldDirectClip(_ model: ZLPhotoModel) -> Bool {
    let config = ZLPhotoConfiguration.default()

    guard config.enableDirectClipFlow else { return false }
    guard config.allowEditImage else { return false }
    guard config.maxSelectCount == 1 else { return false }
    guard model.type.rawValue < ZLPhotoModel.MediaType.video.rawValue else { return false }

    let nav = navigationController as? ZLImageNavController
    let arrSelectedModels = nav?.arrSelectedModels ?? []
    let flag = arrSelectedModels.isEmpty || (arrSelectedModels.count == 1 && arrSelectedModels.first?.ident == model.ident)

    if flag {
        showDirectClipVC(model: model)
    }
    return flag
}
```

#### 3.2.2 `showDirectClipVC(model: ZLPhotoModel)`

- Gets the navigation controller, shows a progress HUD, fetches the image with `ZLPhotoManager.fetchImage(for: model.asset, size: model.previewSize, ...)`.
- On success: call `presentDirectClipVC(image: image, model: model, nav: nav)`.
- On failure: show `showAlertView(localLanguageTextValue(.imageLoadFailed), self)`.
- On timeout: cancel the request and show timeout alert; hide HUD in all paths.

**Code to add:**

```swift
private func showDirectClipVC(model: ZLPhotoModel) {
    guard let nav = navigationController as? ZLImageNavController else {
        return
    }

    var requestAssetID: PHImageRequestID?

    let hud = ZLProgressHUD.show(timeout: ZLPhotoUIConfiguration.default().timeout)
    hud.timeoutBlock = { [weak self] in
        showAlertView(localLanguageTextValue(.timeout), self)
        if let requestAssetID = requestAssetID {
            PHImageManager.default().cancelImageRequest(requestAssetID)
        }
    }

    requestAssetID = ZLPhotoManager.fetchImage(for: model.asset, size: model.previewSize) { [weak self, weak nav] image, isDegraded in
        guard !isDegraded else {
            return
        }
        if let image = image {
            self?.presentDirectClipVC(image: image, model: model, nav: nav)
        } else {
            showAlertView(localLanguageTextValue(.imageLoadFailed), self)
        }
        hud.hide()
    }
}
```

#### 3.2.3 `presentDirectClipVC(image: UIImage, model: ZLPhotoModel, nav: ZLImageNavController?)`

- Build initial clip status: `ZLClipStatus(editRect: CGRect(origin: .zero, size: image.size), angle: 0, ratio: editConfig.clipRatios.first)` so the first configured ratio is pre-selected.
- Create `ZLClipImageViewController(image: image, status: clipStatus, clipRatios: editConfig.clipRatios)` (passing `editConfig.clipRatios` so the crop UI shows the same ratios).
- Set `clipDoneBlock`: compute clipped image with `image.zl.clipImage(angle:angle, editRect:editRect, isCircle: ratio.isCircle)`, build `ZLEditImageModel(clipStatus: ZLClipStatus(editRect:editRect, angle:angle, ratio:ratio))`, set `model.isSelected = true`, `model.editImage = clippedImage`, `model.editImageModel = editModel`, append model to `nav?.arrSelectedModels`, call `ZLPhotoConfiguration.default().didSelectAsset?(model.asset)`, then `self?.doneBtnClick()`.
- Set `cancelClipBlock` to an empty block (just dismiss).
- Set `clipVC.modalPresentationStyle = .fullScreen` and present: `nav?.present(clipVC, animated: true, completion: nil)`.

**Code to add:**

```swift
private func presentDirectClipVC(image: UIImage, model: ZLPhotoModel, nav: ZLImageNavController?) {
    let config = ZLPhotoConfiguration.default()
    let editConfig = config.editImageConfiguration

    let clipStatus = ZLClipStatus(editRect: CGRect(origin: .zero, size: image.size), angle: 0, ratio: editConfig.clipRatios.first)

    let clipVC = ZLClipImageViewController(image: image, status: clipStatus, clipRatios: editConfig.clipRatios)

    clipVC.clipDoneBlock = { [weak self, weak nav] angle, editRect, ratio in
        let clippedImage = image.zl.clipImage(angle: angle, editRect: editRect, isCircle: ratio.isCircle)
        let editModel = ZLEditImageModel(clipStatus: ZLClipStatus(editRect: editRect, angle: angle, ratio: ratio))
        model.isSelected = true
        model.editImage = clippedImage
        model.editImageModel = editModel
        nav?.arrSelectedModels.append(model)
        ZLPhotoConfiguration.default().didSelectAsset?(model.asset)
        self?.doneBtnClick()
    }

    clipVC.cancelClipBlock = { }

    clipVC.modalPresentationStyle = .fullScreen
    nav?.present(clipVC, animated: true, completion: nil)
}
```

**Note:** `ZLClipStatus` in this package is `init(editRect:angle:ratio:)` with `angle` defaulting to 0. If your version differs, use the initializer that matches the rest of the Edit module.

---

## 4. Consumer usage (app / picker layer)

This is **outside** the SPM package: in your app or a wrapper (e.g. `ImagePickerManager`).

- Set config **before** showing the picker:
  - `config.maxSelectCount = 1`
  - `config.allowSelectImage = true` / `config.allowSelectVideo = false` as needed
  - `config.allowPreviewPhotos = showPreview` (e.g. `false` for “tap → crop only”)
  - If you want direct clip:
    - `config.allowEditImage = true`
    - `config.editAfterSelectThumbnailImage = true`
    - `config.saveNewImageAfterEdit = true`
    - `config.editImageConfiguration(editConfig)` with `tools([.clip])` and `clipRatios(yourRatios)`
    - **`config.enableDirectClipFlow = true`**
  - If you do **not** want crop:
    - `config.allowEditImage = false`
    - `config.enableDirectClipFlow = false`
- Show picker as usual; in `selectImageBlock` use `results.first` and call your completion. No API changes to the picker itself.

Example (conceptual) for “single image with optional crop”:

```swift
func pickImage(clipRatios: [ZLImageClipRatio]? = nil, showPreview: Bool = false, from viewController: UIViewController, completion: @escaping (ZLResultModel?) -> Void) {
    let config = ZLPhotoConfiguration.default()
    config.maxSelectCount = 1
    config.allowSelectImage = true
    config.allowSelectVideo = false
    config.allowPreviewPhotos = showPreview

    if let clipRatios = clipRatios, !clipRatios.isEmpty {
        config.allowEditImage = true
        config.editAfterSelectThumbnailImage = true
        config.saveNewImageAfterEdit = true
        let editConfig = ZLEditImageConfiguration()
        editConfig.tools([.clip])
        editConfig.clipRatios(clipRatios)
        config.editImageConfiguration(editConfig)
        config.enableDirectClipFlow = true
    } else {
        config.allowEditImage = false
        config.enableDirectClipFlow = false
    }

    let picker = ZLPhotoPicker()
    picker.selectImageBlock = { results, _ in completion(results.first) }
    picker.showPhotoLibrary(sender: viewController)
}
```

---

## 5. Summary table

| Item | File | Action |
|------|------|--------|
| New property | `ZLPhotoConfiguration.swift` | Add `enableDirectClipFlow = false` after `editAfterSelectThumbnailImage` |
| Tap handling | `ZLThumbnailViewController.swift` | In `didSelectItemAt`, after `let m = arrDataSources[index]`, add `if shouldDirectClip(m) { return }` |
| Helpers | `ZLThumbnailViewController.swift` | Add `shouldDirectClip`, `showDirectClipVC`, `presentDirectClipVC` after `shouldDirectEdit` |

---

## 6. What stays unchanged

- Default `enableDirectClipFlow = false`: no change in behavior.
- Multiselect, preview flow, and “edit after select” (ZLEditImageViewController) flow unchanged when direct clip is not enabled.
- Camera flow: unchanged; direct clip is only for **thumbnail tap** in the library.
- All existing config and picker APIs remain; the only addition is one new config flag and the internal branch that uses it.

This gives you the same “thumbnail → direct crop” flow as in the Demo app, with minimal edits and no breaking changes.
