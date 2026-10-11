import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';
import 'package:lumina_plugin_openxr/runtime.dart';

import 'support/passthrough_rig.dart';

void main() {
  test('no XR_FB_passthrough, blend modes [OPAQUE, ALPHA_BLEND]: frames end with ALPHA_BLEND and a transparent clear', () {
    final rig = PassthroughRig(extension: false, blendModes: const [OpenXrBlendMode.opaque, OpenXrBlendMode.alphaBlend])
      ..begin();
    expect(rig.runtime.mode, MetaPassthroughMode.alphaBlend);
    expect(rig.recorder.calls, isEmpty, reason: 'no passthrough calls without the extension');
    expect(rig.sim.compositions.last.environmentBlendMode, OpenXrBlendMode.alphaBlend);
    expect(rig.sim.compositions.last.transparentBackground, isTrue);
    expect(rig.sim.submittedLayers, ['projection']);
    expect(rig.component.isAvailable, isTrue);
    rig.component.setEnabled(false);
    rig.pacer.tick();
    expect(rig.sim.compositions.last.environmentBlendMode, OpenXrBlendMode.opaque);
  });

  test('neither: isAvailable false and no passthrough calls', () {
    final rig = PassthroughRig(extension: false)..begin();
    expect(rig.runtime.mode, MetaPassthroughMode.unavailable);
    expect(rig.component.isAvailable, isFalse);
    expect(rig.recorder.calls, isEmpty);
    expect(rig.sim.submittedLayers, ['projection']);
  });
}
