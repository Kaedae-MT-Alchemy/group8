import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Firestore rejects documents over 1 MB, so photos are resized and saved as
/// JPEG before they are stored. Returns null if the bytes are not an image.
Uint8List? compressImage(
  Uint8List bytes, {
  int maxSide = 1200,
  int targetBytes = 300 * 1024,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  if (image.width > maxSide || image.height > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }
  var quality = 82;
  var out = img.encodeJpg(image, quality: quality);
  while (out.length > targetBytes && quality > 40) {
    quality -= 10;
    out = img.encodeJpg(image, quality: quality);
  }
  while (out.length > targetBytes && image.width > 320) {
    image = img.copyResize(image, width: (image.width * 0.75).round());
    out = img.encodeJpg(image, quality: quality);
  }
  return Uint8List.fromList(out);
}
