import 'package:lumina/lumina.dart';

import 'package:lumina_plugin_metaxr/src/passthrough/lumina_meta_passthrough_component.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_style.dart';

/// What the passthrough Blueprint nodes call: they act on the first
/// `LuminaMetaPassthroughComponent` in the actor's world.
abstract final class MetaPassthroughFunctions {
  static LuminaMetaPassthroughComponent? component(LuminaActor self) {
    final world = self.world;
    if (world == null) return null;
    for (final actor in world.actors) {
      for (final c in actor.components) {
        if (c is LuminaMetaPassthroughComponent) return c;
      }
    }
    return null;
  }

  static void setEnabled(LuminaActor self, bool enabled) => component(self)?.setEnabled(enabled);

  /// [edgeColor] is linear RGBA 0..1; alpha 0 turns edge rendering off.
  static void setStyle(LuminaActor self, double opacity, List<double> edgeColor, double brightness, double contrast,
      double saturation) {
    final c = component(self);
    if (c == null) return;
    int byte(double v) => (v.clamp(0.0, 1.0) * 255).round();
    final rgba = edgeColor.length < 4
        ? 0
        : (byte(edgeColor[0]) << 24) | (byte(edgeColor[1]) << 16) | (byte(edgeColor[2]) << 8) | byte(edgeColor[3]);
    c.setStyle(MetaPassthroughStyle(
      opacity: opacity,
      enableEdgeRendering: edgeColor.length >= 4 && edgeColor[3] > 0,
      edgeColorRgba: rgba,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
    ));
  }

  static bool isAvailable(LuminaActor self) => component(self)?.isAvailable ?? false;
}

/// The passthrough Blueprint nodes (category *XR | Passthrough*): Set
/// Passthrough Enabled, Set Passthrough Style, Is Passthrough Available.
abstract final class MetaPassthroughNodes {
  static const _category = 'XR|Passthrough';
  static const _color = 0xFF5E35B1;
  static const _library = 'package:lumina_plugin_metaxr/runtime.dart';
  static const setEnabledId = 'metaxr_set_passthrough_enabled';
  static const setStyleId = 'metaxr_set_passthrough_style';
  static const isAvailableId = 'metaxr_is_passthrough_available';
  static const ids = [setEnabledId, setStyleId, isAvailableId];

  static double _n(Object? v, double fallback) => v is num ? v.toDouble() : fallback;

  /// Registers the nodes once.
  static void register() {
    if (LuminaBlueprintFunctionRegistry.entry(setEnabledId) != null) return;
    LuminaBlueprintFunctionRegistry.register(
      const LuminaBlueprintNodeSpec(
        id: setEnabledId,
        title: 'Set Passthrough Enabled',
        category: _category,
        kind: LuminaBlueprintNodeKind.impure,
        headerColor: _color,
        keywords: ['xr', 'mixed reality', 'passthrough', 'room'],
        tooltip: 'Shows (or hides) the user\'s room through the passthrough layer.',
        inputs: [
          LuminaBlueprintPinSpec('exec_in', 'Exec In', LuminaPinType.exec),
          LuminaBlueprintPinSpec('enabled', 'Enabled', LuminaPinType.boolean, defaultValue: true),
        ],
        outputs: [LuminaBlueprintPinSpec('exec_out', 'Exec Out', LuminaPinType.exec)],
      ),
      (c, i) {
        MetaPassthroughFunctions.setEnabled(c.self, i['enabled'] as bool? ?? true);
        return const {};
      },
      call: const LuminaBlueprintCallShape('MetaPassthroughFunctions.setEnabled', ['enabled'], self: true, library: _library),
    );
    LuminaBlueprintFunctionRegistry.register(
      const LuminaBlueprintNodeSpec(
        id: setStyleId,
        title: 'Set Passthrough Style',
        category: _category,
        kind: LuminaBlueprintNodeKind.impure,
        headerColor: _color,
        keywords: ['xr', 'passthrough', 'edge', 'opacity', 'brightness', 'contrast', 'saturation'],
        tooltip: 'Opacity 0 to 1, edge colour (alpha 0: no edges), brightness -100 to 100, contrast and saturation (1: unchanged).',
        inputs: [
          LuminaBlueprintPinSpec('exec_in', 'Exec In', LuminaPinType.exec),
          LuminaBlueprintPinSpec('opacity', 'Opacity', LuminaPinType.float, defaultValue: 1.0),
          LuminaBlueprintPinSpec('edge_color', 'Edge Color', LuminaPinType.color, defaultValue: [0.0, 0.0, 0.0, 0.0]),
          LuminaBlueprintPinSpec('brightness', 'Brightness', LuminaPinType.float, defaultValue: 0.0),
          LuminaBlueprintPinSpec('contrast', 'Contrast', LuminaPinType.float, defaultValue: 1.0),
          LuminaBlueprintPinSpec('saturation', 'Saturation', LuminaPinType.float, defaultValue: 1.0),
        ],
        outputs: [LuminaBlueprintPinSpec('exec_out', 'Exec Out', LuminaPinType.exec)],
      ),
      (c, i) {
        final edge = i['edge_color'];
        MetaPassthroughFunctions.setStyle(
          c.self,
          _n(i['opacity'], 1),
          edge is List ? [for (final v in edge) _n(v, 0)] : const [0.0, 0.0, 0.0, 0.0],
          _n(i['brightness'], 0),
          _n(i['contrast'], 1),
          _n(i['saturation'], 1),
        );
        return const {};
      },
      call: const LuminaBlueprintCallShape('MetaPassthroughFunctions.setStyle',
          ['opacity', 'edge_color', 'brightness', 'contrast', 'saturation'],
          self: true, library: _library),
    );
    LuminaBlueprintFunctionRegistry.register(
      const LuminaBlueprintNodeSpec(
        id: isAvailableId,
        title: 'Is Passthrough Available',
        category: _category,
        kind: LuminaBlueprintNodeKind.pure,
        headerColor: _color,
        keywords: ['xr', 'passthrough', 'mixed reality'],
        tooltip: 'Whether the headset can show the room (XR_FB_passthrough or an alpha-blend environment).',
        inputs: [],
        outputs: [LuminaBlueprintPinSpec('return_value', 'Return Value', LuminaPinType.boolean)],
      ),
      (c, i) => {'return_value': MetaPassthroughFunctions.isAvailable(c.self)},
      call: const LuminaBlueprintCallShape('MetaPassthroughFunctions.isAvailable', [],
          self: true, library: _library, outputs: ['return_value']),
    );
  }

  static void unregister() {
    for (final id in ids) {
      LuminaBlueprintFunctionRegistry.unregister(id);
    }
  }
}

/// The Android manifest line a Quest build needs for passthrough
/// (`xrCreatePassthroughFB` fails with `XR_ERROR_FEATURE_UNSUPPORTED_FB`
/// without it); required when a level uses the passthrough component.
abstract final class MetaPassthroughManifest {
  static String usesFeature({required bool required}) =>
      '<uses-feature android:name="com.oculus.feature.PASSTHROUGH" android:required="$required"/>';
}
