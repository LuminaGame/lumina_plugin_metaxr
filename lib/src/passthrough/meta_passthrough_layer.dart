import 'meta_passthrough_style.dart';

/// Purpose of the passthrough layer.
enum MetaPassthroughPurpose {
  /// Full-environment camera reconstruction layer.
  reconstruction,

  /// Geometry-projected surface layer (cutouts / portals).
  projectedSurface,
}

/// Compositor placement of the passthrough layer.
enum MetaPassthroughPlacement {
  /// Rendered behind the virtual world (standard mixed reality mode).
  underlay,

  /// Rendered in front of the virtual world.
  overlay,
}

/// Lifecycle state of a passthrough layer.
enum MetaPassthroughState {
  uninitialized,
  running,
  paused,
  destroyed,
}

/// Represents an active or paused Meta Quest passthrough layer.
class MetaPassthroughLayer {
  final MetaPassthroughPurpose purpose;
  MetaPassthroughPlacement placement;
  MetaPassthroughStyle style;
  MetaPassthroughState _state = MetaPassthroughState.uninitialized;

  MetaPassthroughLayer({
    this.purpose = MetaPassthroughPurpose.reconstruction,
    this.placement = MetaPassthroughPlacement.underlay,
    this.style = const MetaPassthroughStyle(),
  });

  MetaPassthroughState get state => _state;
  bool get isRunning => _state == MetaPassthroughState.running;

  void start() {
    _state = MetaPassthroughState.running;
  }

  void pause() {
    _state = MetaPassthroughState.paused;
  }

  void resume() {
    _state = MetaPassthroughState.running;
  }

  void destroy() {
    _state = MetaPassthroughState.destroyed;
  }
}
