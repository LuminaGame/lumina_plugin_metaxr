import 'dart:typed_data';

import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_backend.dart';

/// The editor-side stand-in for the headset's compositor: a camera-feed image
/// styled like `XrPassthroughStyleFB` (brightness / contrast / saturation,
/// edge colour, texture opacity) and the game's eye image blended over it
/// with its alpha, as the runtime does with an underlay and a projection
/// layer flagged `BLEND_TEXTURE_SOURCE_ALPHA | UNPREMULTIPLIED_ALPHA`.
abstract final class MetaPassthroughSimulator {
  /// [feed] styled by [style] (RGBA8, [width] x [height]).
  static Uint8List styleFeed(Uint8List feed, int width, int height, MetaPassthroughStyleFB style) {
    final out = Uint8List(feed.length);
    final luminance = Float32List(width * height);
    for (var i = 0, p = 0; p < luminance.length; i += 4, p++) {
      var r = feed[i] / 255, g = feed[i + 1] / 255, b = feed[i + 2] / 255;
      final l = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      // Saturation around the luminance, contrast around mid grey, brightness as an offset.
      r = l + (r - l) * style.saturation;
      g = l + (g - l) * style.saturation;
      b = l + (b - l) * style.saturation;
      r = (r - 0.5) * style.contrast + 0.5 + style.brightness / 100;
      g = (g - 0.5) * style.contrast + 0.5 + style.brightness / 100;
      b = (b - 0.5) * style.contrast + 0.5 + style.brightness / 100;
      luminance[p] = l;
      out[i] = (r.clamp(0.0, 1.0) * 255 * style.opacity).round();
      out[i + 1] = (g.clamp(0.0, 1.0) * 255 * style.opacity).round();
      out[i + 2] = (b.clamp(0.0, 1.0) * 255 * style.opacity).round();
      out[i + 3] = 255;
    }
    final edgeAlpha = style.edgeColor[3];
    if (edgeAlpha > 0) {
      for (var y = 1; y < height - 1; y++) {
        for (var x = 1; x < width - 1; x++) {
          final p = y * width + x;
          final gx = luminance[p + 1] - luminance[p - 1];
          final gy = luminance[p + width] - luminance[p - width];
          final e = ((gx.abs() + gy.abs()) * 4).clamp(0.0, 1.0) * edgeAlpha;
          if (e <= 0) continue;
          final i = p * 4;
          for (var c = 0; c < 3; c++) {
            out[i + c] = (out[i + c] * (1 - e) + style.edgeColor[c] * 255 * e).round();
          }
        }
      }
    }
    return out;
  }

  /// [eye] (RGBA8, unpremultiplied, alpha 0 where the game drew nothing) over
  /// [styledFeed]: `eye * a + feed * (1 - a)`.
  static Uint8List composite(Uint8List eye, Uint8List styledFeed) {
    final out = Uint8List(eye.length);
    for (var i = 0; i < eye.length; i += 4) {
      final a = eye[i + 3] / 255;
      for (var c = 0; c < 3; c++) {
        out[i + c] = (eye[i + c] * a + styledFeed[i + c] * (1 - a)).round();
      }
      out[i + 3] = 255;
    }
    return out;
  }
}
