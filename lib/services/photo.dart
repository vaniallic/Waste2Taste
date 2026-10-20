import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Phone photos are several MB, too big to send for scanning. This shrinks a
/// photo to about 1024 px wide and saves it as a JPEG (a few hundred KB).
/// Small photos, or anything that can't be decoded, come back unchanged.
Future<Uint8List> shrinkPhoto(Uint8List bytes) async {
  if (bytes.lengthInBytes < 500 * 1024) return bytes;
  try {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1024);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return bytes;
    final small = img.Image.fromBytes(
      width: frame.image.width,
      height: frame.image.height,
      bytes: data.buffer,
      numChannels: 4,
    );
    return Uint8List.fromList(img.encodeJpg(small, quality: 75));
  } catch (_) {
    return bytes;
  }
}
