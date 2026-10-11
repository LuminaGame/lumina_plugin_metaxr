import 'package:lumina_plugin_metaxr/runtime.dart';
import 'package:lumina_plugin_openxr/runtime.dart';

/// A scripted openxr session on the simulated headset with a passthrough
/// runtime recording its native calls.
class PassthroughRig {
  PassthroughRig({bool extension = true, List<int>? blendModes, LuminaMetaPassthroughComponent? component}) {
    sim = _BlendSim(blendModes ?? const [OpenXrBlendMode.opaque]);
    if (extension) sim.offeredExtensions.add(MetaOpenXrExtensions.passthrough);
    session = OpenXrSession(backend: sim);
    pacer = OpenXrSimulatedPacer(sim, automatic: false);
    loop = OpenXrFrameLoop(pacer: pacer, renderer: _Renderer());
    runtime = MetaPassthroughRuntime(openxr: sim, passthrough: recorder);
    this.component = component ?? LuminaMetaPassthroughComponent();
    runtime
      ..bind(this.component)
      ..attach(session, loop);
  }

  late final SimulatedOpenXrBackend sim;
  late final OpenXrSession session;
  late final OpenXrSimulatedPacer pacer;
  late final OpenXrFrameLoop loop;
  late final MetaPassthroughRuntime runtime;
  late final LuminaMetaPassthroughComponent component;
  final recorder = MetaPassthroughRecorder();

  /// Begins the session (READY creates the passthrough) and runs one frame.
  void begin() {
    session.beginSession();
    loop.start();
    pacer.tick();
  }
}

class _BlendSim extends SimulatedOpenXrBackend {
  _BlendSim(this._modes);
  final List<int> _modes;

  @override
  List<int> get blendModes => _modes;
}

class _Renderer implements OpenXrEyeRenderer, OpenXrTransparencyAware {
  bool transparent = false;

  @override
  set transparentBackground(bool value) => transparent = value;

  @override
  bool render(OpenXrFrame frame, List<OpenXrEyeView> views) => true;
}
