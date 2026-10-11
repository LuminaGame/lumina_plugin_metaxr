import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';
import 'package:lumina_plugin_openxr/runtime.dart';

import 'support/passthrough_rig.dart';

void main() {
  test('underlay: [passthrough, projection], the projection layer alpha-blended, the game clears to alpha 0', () {
    final rig = PassthroughRig()..begin();
    expect(rig.sim.submittedLayers, ['passthrough', 'projection']);
    final composition = rig.sim.compositions.last;
    expect(composition.projectionFlags,
        OpenXrCompositionLayerFlags.blendTextureSourceAlpha | OpenXrCompositionLayerFlags.unpremultipliedAlpha);
    expect(composition.transparentBackground, isTrue);
    expect(composition.environmentBlendMode, OpenXrBlendMode.opaque);
  });

  test('overlay: [projection, passthrough] and the projection layer keeps its flags', () {
    final rig = PassthroughRig(
        component: LuminaMetaPassthroughComponent(placement: MetaPassthroughPlacement.overlay))
      ..begin();
    expect(rig.sim.submittedLayers, ['projection', 'passthrough']);
    expect(rig.sim.compositions.last.projectionFlags, 0);
    expect(rig.sim.compositions.last.transparentBackground, isFalse);
  });

  test('disabled: only the projection layer, opaque again', () {
    final rig = PassthroughRig()..begin();
    rig.component.setEnabled(false);
    rig.pacer.tick();
    expect(rig.sim.submittedLayers, ['projection']);
    expect(rig.sim.compositions.last.transparentBackground, isFalse);
  });
}
