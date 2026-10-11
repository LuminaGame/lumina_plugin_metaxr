import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:lumina_plugin_openxr/runtime.dart';

import 'package:lumina_plugin_metaxr/src/passthrough/ffi/metaxr_passthrough_ffi.dart' as n;
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_layer.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_style.dart';

final _log = Logger('MetaXR.passthrough');

/// The style as `XrPassthroughStyleFB` takes it: texture opacity, edge colour
/// (alpha 0 without edge rendering) and the brightness / contrast /
/// saturation struct chained in its `next`.
class MetaPassthroughStyleFB {
  const MetaPassthroughStyleFB(
      {required this.opacity, required this.edgeColor, required this.brightness, required this.contrast, required this.saturation});

  factory MetaPassthroughStyleFB.of(MetaPassthroughStyle style) {
    final c = style.edgeColorRgba;
    final edge = style.enableEdgeRendering
        ? [((c >> 24) & 0xFF) / 255, ((c >> 16) & 0xFF) / 255, ((c >> 8) & 0xFF) / 255, (c & 0xFF) / 255]
        : const [0.0, 0.0, 0.0, 0.0];
    return MetaPassthroughStyleFB(
      opacity: style.opacity.clamp(0.0, 1.0),
      edgeColor: edge,
      brightness: style.brightness.clamp(-100.0, 100.0),
      contrast: style.contrast < 0 ? 0 : style.contrast,
      saturation: style.saturation < 0 ? 0 : style.saturation,
    );
  }

  final double opacity;
  final List<double> edgeColor;
  final double brightness;
  final double contrast;
  final double saturation;

  @override
  String toString() => 'opacity $opacity, edge $edgeColor, bcs ($brightness, $contrast, $saturation)';
}

/// The `XR_FB_passthrough` calls: the native bridge on a headset, a recorder
/// in tests and on the simulated headset.
abstract interface class MetaPassthroughBackend {
  /// `xrCreatePassthroughFB` on [openxr]'s session.
  XrResult create(OpenXrBackend openxr, {required bool running});
  XrResult createLayer(MetaPassthroughPurpose purpose, {required bool running});
  XrResult start();
  XrResult pause();
  XrResult resumeLayer();
  XrResult pauseLayer();
  XrResult setStyle(MetaPassthroughStyleFB style);

  /// The address of the layer's `XrCompositionLayerPassthroughFB` (0: none).
  int get layerAddress;
  void destroy();
}

/// Records every call (tests, the simulated headset): `calls` names them in
/// order, `styles` keeps the styles set.
class MetaPassthroughRecorder implements MetaPassthroughBackend {
  final List<String> calls = [];
  final List<MetaPassthroughStyleFB> styles = [];
  bool _layer = false;

  XrResult _record(String call) {
    calls.add(call);
    return XrResult.success;
  }

  @override
  XrResult create(OpenXrBackend openxr, {required bool running}) => _record('xrCreatePassthroughFB');

  @override
  XrResult createLayer(MetaPassthroughPurpose purpose, {required bool running}) {
    _layer = true;
    return _record('xrCreatePassthroughLayerFB(${purpose.name})');
  }

  @override
  XrResult start() => _record('xrPassthroughStartFB');
  @override
  XrResult pause() => _record('xrPassthroughPauseFB');
  @override
  XrResult resumeLayer() => _record('xrPassthroughLayerResumeFB');
  @override
  XrResult pauseLayer() => _record('xrPassthroughLayerPauseFB');

  @override
  XrResult setStyle(MetaPassthroughStyleFB style) {
    styles.add(style);
    return _record('xrPassthroughLayerSetStyleFB');
  }

  /// A stand-in address (the simulated compositor knows the layer by name).
  @override
  int get layerAddress => _layer ? 0x5054 : 0;

  @override
  void destroy() {
    _layer = false;
    _record('destroy');
  }
}

/// `XR_FB_passthrough` through the plugin's native code on the openxr
/// plugin's instance. Every call is guarded: a native failure is reported
/// through `OpenXrErrorReporter`, never thrown.
class MetaPassthroughNative implements MetaPassthroughBackend {
  XrResult _call(String what, int Function() call) {
    final r = XrResult.fromValue(OpenXrErrorReporter.guard(what, call, XrResult.errorRuntimeFailure.value));
    if (r.isFailure) {
      _log.warning('$what: ${OpenXrErrorReporter.guard('lastError', () => n.metaxr_passthrough_last_error().toDartString(), '')}');
    }
    return r;
  }

  @override
  XrResult create(OpenXrBackend openxr, {required bool running}) {
    if (openxr is! OpenXrNativeBackend) return XrResult.errorExtensionNotPresent;
    return _call('xrCreatePassthroughFB',
        () => n.metaxr_passthrough_create(openxr.instanceProcAddr, openxr.instanceHandle, openxr.sessionHandle, running));
  }

  @override
  XrResult createLayer(MetaPassthroughPurpose purpose, {required bool running}) => _call('xrCreatePassthroughLayerFB',
      () => n.metaxr_passthrough_layer_create(purpose == MetaPassthroughPurpose.projectedSurface ? 1 : 0, running));

  @override
  XrResult start() => _call('xrPassthroughStartFB', n.metaxr_passthrough_start);
  @override
  XrResult pause() => _call('xrPassthroughPauseFB', n.metaxr_passthrough_pause);
  @override
  XrResult resumeLayer() => _call('xrPassthroughLayerResumeFB', n.metaxr_passthrough_layer_resume);
  @override
  XrResult pauseLayer() => _call('xrPassthroughLayerPauseFB', n.metaxr_passthrough_layer_pause);

  @override
  XrResult setStyle(MetaPassthroughStyleFB style) => _call(
      'xrPassthroughLayerSetStyleFB',
      () => using((arena) {
            final s = arena<n.MetaxrPassthroughStyleNative>();
            s.ref
              ..opacity = style.opacity
              ..brightness = style.brightness
              ..contrast = style.contrast
              ..saturation = style.saturation;
            for (var i = 0; i < 4; i++) {
              s.ref.edgeColor[i] = style.edgeColor[i];
            }
            return n.metaxr_passthrough_set_style(s);
          }));

  @override
  int get layerAddress => OpenXrErrorReporter.guard('layerHeader', () => n.metaxr_passthrough_layer_header().address, 0);

  @override
  void destroy() => OpenXrErrorReporter.guard('destroyPassthrough', n.metaxr_passthrough_destroy, null);
}
