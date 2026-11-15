import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Compresses and center-crops an avatar image to 256x256 PNG (PRD 2.2 / 15C).
abstract final class AvatarCompressor {
  static Uint8List? compressTo256Png(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      return null;
    }

    final oriented = img.bakeOrientation(decoded);
    final size =
        oriented.width < oriented.height ? oriented.width : oriented.height;
    final offsetX = (oriented.width - size) ~/ 2;
    final offsetY = (oriented.height - size) ~/ 2;

    final cropped = img.copyCrop(
      oriented,
      x: offsetX,
      y: offsetY,
      width: size,
      height: size,
    );

    final resized = img.copyResize(
      cropped,
      width: 256,
      height: 256,
      interpolation: img.Interpolation.average,
    );

    return Uint8List.fromList(img.encodePng(resized, level: 6));
  }
}
