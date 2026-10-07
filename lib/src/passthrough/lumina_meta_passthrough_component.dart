import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_layer.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_style.dart';

/// Scene component managing Meta Quest mixed reality passthrough layer and styling.
class LuminaMetaPassthroughComponent extends LuminaSceneComponent {
  bool isEnabled;
  final MetaPassthroughLayer layer;

  LuminaMetaPassthroughComponent({
    super.key,
    super.location,
    super.rotation,
    this.isEnabled = true,
    MetaPassthroughPurpose purpose = MetaPassthroughPurpose.reconstruction,
    MetaPassthroughPlacement placement = MetaPassthroughPlacement.underlay,
    MetaPassthroughStyle style = const MetaPassthroughStyle(),
  }) : layer = MetaPassthroughLayer(
          purpose: purpose,
          placement: placement,
          style: style,
        ) {
    if (isEnabled) {
      layer.start();
    }
  }

  /// Sets whether the passthrough layer is active.
  void setEnabled(bool enabled) {
    if (isEnabled == enabled) return;
    isEnabled = enabled;
    if (isEnabled) {
      layer.start();
    } else {
      layer.pause();
    }
  }

  /// Updates passthrough visual style parameters.
  void setStyle(MetaPassthroughStyle newStyle) {
    layer.style = newStyle;
  }
}
