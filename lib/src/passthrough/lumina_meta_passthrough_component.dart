import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_layer.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_style.dart';

/// What the component asks of the runtime that drives it
/// (`MetaPassthroughRuntime`).
abstract interface class MetaPassthroughDriver {
  bool get isAvailable;
  void enabledChanged(LuminaMetaPassthroughComponent component);
  void styleChanged(LuminaMetaPassthroughComponent component);
}

/// Mixed reality passthrough for a level: the user's room shown under (or
/// over) the game. Without a runtime (the editor, a desktop game) it only
/// keeps its state; bound to `MetaPassthroughRuntime` on a headset,
/// [setEnabled] and [setStyle] reach the runtime and [layer]'s state follows
/// the runtime's events.
class LuminaMetaPassthroughComponent extends LuminaSceneComponent {
  bool isEnabled;
  final MetaPassthroughLayer layer;

  /// The runtime driving this component, or null.
  MetaPassthroughDriver? driver;

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

  /// Whether passthrough can be shown here: a runtime drives the component
  /// and the headset offers passthrough (`XR_FB_passthrough` or an alpha-blend
  /// environment).
  bool get isAvailable => driver?.isAvailable ?? false;

  /// Whether the runtime reported a non-recoverable passthrough error.
  bool get hasFailed => layer.state == MetaPassthroughState.failed;

  /// Sets whether the passthrough layer is active.
  void setEnabled(bool enabled) {
    if (isEnabled == enabled) return;
    isEnabled = enabled;
    final d = driver;
    if (d != null) {
      d.enabledChanged(this);
    } else if (isEnabled) {
      layer.start();
    } else {
      layer.pause();
    }
  }

  /// Updates passthrough visual style parameters.
  void setStyle(MetaPassthroughStyle newStyle) {
    layer.style = newStyle;
    driver?.styleChanged(this);
  }
}
