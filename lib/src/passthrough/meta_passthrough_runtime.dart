import 'package:logging/logging.dart';
import 'package:lumina/lumina.dart' show LuminaWorld;
import 'package:lumina_plugin_openxr/runtime.dart';

import 'package:lumina_plugin_metaxr/src/meta_extensions.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/lumina_meta_passthrough_component.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_backend.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_layer.dart';

final _log = Logger('MetaXR.passthrough');

/// How passthrough reaches the display.
enum MetaPassthroughMode {
  /// Not started yet.
  none,

  /// `XR_FB_passthrough`: a passthrough layer under (or over) the projection layer.
  layer,

  /// No FB extension, but the runtime blends with the environment (`ALPHA_BLEND`).
  alphaBlend,

  /// Neither: no passthrough on this runtime.
  unavailable,
}

/// `XR_TYPE_EVENT_DATA_PASSTHROUGH_STATE_CHANGED_FB` and its flags.
abstract final class MetaPassthroughEvents {
  static const stateChangedType = 1000118030;
  static const reinitRequired = 0x1;
  static const nonRecoverableError = 0x2;
  static const recoverableError = 0x4;
  static const restoredError = 0x8;
}

/// Drives `LuminaMetaPassthroughComponent`s on the openxr plugin's session:
/// when the session is READY it creates the `XR_FB_passthrough` feature and
/// a layer (or falls back to the `ALPHA_BLEND` environment blend mode), and
/// as an `OpenXrLayerContributor` it gives the frame loop the passthrough
/// layer under the projection layer, the projection layer's alpha bits and a
/// transparent clear while passthrough is on.
class MetaPassthroughRuntime implements OpenXrLayerContributor, MetaPassthroughDriver {
  MetaPassthroughRuntime({required this.openxr, MetaPassthroughBackend? passthrough})
      : passthrough = passthrough ?? (openxr.isNative ? MetaPassthroughNative() : MetaPassthroughRecorder());

  /// Asks the openxr session for `XR_FB_passthrough` (before the instance is created).
  static void requestExtension() => OpenXrExtensionRequests.add(MetaOpenXrExtensions.passthrough);

  final OpenXrBackend openxr;
  final MetaPassthroughBackend passthrough;
  final List<LuminaMetaPassthroughComponent> _components = [];
  MetaPassthroughMode _mode = MetaPassthroughMode.none;

  MetaPassthroughMode get mode => _mode;

  @override
  bool get isAvailable => _mode == MetaPassthroughMode.layer || _mode == MetaPassthroughMode.alphaBlend;

  /// The component in charge (the first bound one).
  LuminaMetaPassthroughComponent? get component => _components.isEmpty ? null : _components.first;

  /// Hooks into [session] (READY starts passthrough, passthrough events
  /// drive the layer) and [loop] (the layers every frame).
  void attach(OpenXrSession session, OpenXrFrameLoop loop) {
    session.eventListeners.add(onEvent);
    if (!loop.layerContributors.contains(this)) loop.layerContributors.add(this);
    // Attached after READY (from onSessionBegan): start now.
    final s = session.state.value;
    if (s >= OpenXrSessionState.ready.value && s <= OpenXrSessionState.focused.value) start();
  }

  void detach(OpenXrSession session, OpenXrFrameLoop loop) {
    session.eventListeners.remove(onEvent);
    loop.layerContributors.remove(this);
  }

  /// Binds [component]: its enable / style changes reach the runtime.
  void bind(LuminaMetaPassthroughComponent component) {
    if (_components.contains(component)) return;
    _components.add(component);
    component.driver = this;
    if (_mode == MetaPassthroughMode.layer) {
      styleChanged(component);
      enabledChanged(component);
    }
  }

  void unbind(LuminaMetaPassthroughComponent component) {
    if (_components.remove(component)) component.driver = null;
  }

  /// Binds every passthrough component of [world]'s actors.
  void bindWorld(LuminaWorld world) {
    for (final actor in world.actors) {
      for (final c in actor.components.whereType<LuminaMetaPassthroughComponent>()) {
        bind(c);
      }
    }
  }

  /// The runtime's events: READY starts passthrough, passthrough state
  /// changes move the layer.
  void onEvent(OpenXrRuntimeEvent event) {
    if (event is OpenXrSessionStateChanged && event.state == OpenXrSessionState.ready) {
      start();
    } else if (event is OpenXrOtherEvent && event.structureType == MetaPassthroughEvents.stateChangedType) {
      _stateChanged(event.payload);
    }
  }

  /// Creates the passthrough (or picks the fallback). Called on READY.
  void start() {
    if (_mode != MetaPassthroughMode.none) return;
    final c = component;
    final enabled = c?.isEnabled ?? true;
    if (openxr.extensionEnabled(MetaOpenXrExtensions.passthrough)) {
      final purpose = c?.layer.purpose ?? MetaPassthroughPurpose.reconstruction;
      if (passthrough.create(openxr, running: true).isSuccess &&
          passthrough.createLayer(purpose, running: enabled).isSuccess) {
        _mode = MetaPassthroughMode.layer;
        if (c != null) {
          passthrough.setStyle(MetaPassthroughStyleFB.of(c.layer.style));
          c.layer.runtimeState(enabled ? MetaPassthroughState.running : MetaPassthroughState.paused);
        }
        _log.info('passthrough layer created (${purpose.name}), ${enabled ? 'running' : 'paused'}');
        return;
      }
      _log.warning('XR_FB_passthrough is enabled but the passthrough could not be created');
    }
    if (openxr.blendModes.contains(OpenXrBlendMode.alphaBlend)) {
      _mode = MetaPassthroughMode.alphaBlend;
      c?.layer.runtimeState(enabled ? MetaPassthroughState.running : MetaPassthroughState.paused);
      _log.info('no XR_FB_passthrough: passthrough through the ALPHA_BLEND environment blend mode');
    } else {
      _mode = MetaPassthroughMode.unavailable;
      _log.info('passthrough unavailable (no XR_FB_passthrough, no ALPHA_BLEND)');
    }
  }

  void _stateChanged(int flags) {
    final layer = component?.layer;
    if (flags & MetaPassthroughEvents.nonRecoverableError != 0) {
      layer?.runtimeState(MetaPassthroughState.failed);
      _log.warning('passthrough failed (non-recoverable)');
    } else if (flags & MetaPassthroughEvents.recoverableError != 0) {
      layer?.runtimeState(MetaPassthroughState.recovering);
    } else if (flags & MetaPassthroughEvents.restoredError != 0) {
      final enabled = component?.isEnabled ?? false;
      layer?.runtimeState(enabled ? MetaPassthroughState.running : MetaPassthroughState.paused);
    }
  }

  bool get _showing {
    final c = component;
    return c != null && c.isEnabled && c.layer.isRunning;
  }

  // --- MetaPassthroughDriver ----------------------------------------------------

  @override
  void enabledChanged(LuminaMetaPassthroughComponent c) {
    if (c.hasFailed) return;
    if (_mode == MetaPassthroughMode.layer) {
      final r = c.isEnabled ? passthrough.resumeLayer() : passthrough.pauseLayer();
      if (r.isSuccess) c.layer.runtimeState(c.isEnabled ? MetaPassthroughState.running : MetaPassthroughState.paused);
    } else if (_mode == MetaPassthroughMode.alphaBlend) {
      c.layer.runtimeState(c.isEnabled ? MetaPassthroughState.running : MetaPassthroughState.paused);
    }
  }

  @override
  void styleChanged(LuminaMetaPassthroughComponent c) {
    if (_mode == MetaPassthroughMode.layer) passthrough.setStyle(MetaPassthroughStyleFB.of(c.layer.style));
  }

  // --- OpenXrLayerContributor ------------------------------------------------------

  OpenXrCompositionLayer? get _layer {
    final address = passthrough.layerAddress;
    return _mode == MetaPassthroughMode.layer && _showing && address != 0
        ? OpenXrCompositionLayer('passthrough', address)
        : null;
  }

  bool get _underlay => component?.layer.placement != MetaPassthroughPlacement.overlay;

  @override
  List<OpenXrCompositionLayer> layersBefore(int displayTime) {
    final l = _layer;
    return l != null && _underlay ? [l] : const [];
  }

  @override
  List<OpenXrCompositionLayer> layersAfter(int displayTime) {
    final l = _layer;
    return l != null && !_underlay ? [l] : const [];
  }

  @override
  int get projectionLayerFlags => _layer != null && _underlay
      ? OpenXrCompositionLayerFlags.blendTextureSourceAlpha | OpenXrCompositionLayerFlags.unpremultipliedAlpha
      : 0;

  @override
  int? get environmentBlendMode => _mode == MetaPassthroughMode.alphaBlend && _showing ? OpenXrBlendMode.alphaBlend : null;

  @override
  bool get transparentBackground =>
      (_layer != null && _underlay) || (_mode == MetaPassthroughMode.alphaBlend && _showing);

  /// Destroys the passthrough (before the session goes).
  void dispose() {
    if (_mode == MetaPassthroughMode.layer) passthrough.destroy();
    _mode = MetaPassthroughMode.none;
    for (final c in List.of(_components)) {
      unbind(c);
    }
  }
}
