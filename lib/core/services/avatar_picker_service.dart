import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Source options for selecting a profile avatar across platforms.
enum AvatarPickSource { gallery, camera }

/// Picks and reads avatar image bytes cleanly across Android, iOS, Web,
/// Windows, macOS, and Linux.
class AvatarPickerService {
  AvatarPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Camera capture is offered directly on mobile devices (Android / iOS).
  /// Desktop uses native File Explorer / Finder / GTK File Chooser; Web uses
  /// `<input type="file" accept="image/*">` natively in the browser.
  bool get supportsCameraChoice =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<Uint8List?> pickImageBytes({
    AvatarPickSource source = AvatarPickSource.gallery,
  }) async {
    // Desktop backends do not support ImageSource.camera directly.
    final resolvedSource =
        (source == AvatarPickSource.camera && supportsCameraChoice)
            ? ImageSource.camera
            : ImageSource.gallery;

    final usePreResize =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    final file = await _picker.pickImage(
      source: resolvedSource,
      maxWidth: usePreResize ? 1024 : null,
      maxHeight: usePreResize ? 1024 : null,
      imageQuality: usePreResize ? 90 : null,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Recovers any pending picked photo if Android destroyed MainActivity
  /// while the external gallery/camera activity was open.
  Future<Uint8List?> retrieveLostAndroidBytes() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    if (response.file != null) {
      return response.file!.readAsBytes();
    }
    if (response.exception != null) {
      throw response.exception!;
    }
    return null;
  }
}
