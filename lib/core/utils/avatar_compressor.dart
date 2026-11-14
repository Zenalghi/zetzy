import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Compresses and center-crops an avatar image to 256x256 PNG (PRD 2.2 / 15C).
abstract final class AvatarCompressor {
  static Uint8List? compressTo256Png(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return null;

    final size = decoded.width < decoded.height ? decoded.width : decoded.height;
    final offsetX = (decoded.width - size) ~/ 2;
    final offsetY = (decoded.height - size) ~/ 2;

    final cropped = img.copyCrop(
      decoded,
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
