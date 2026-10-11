import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';

import 'support/passthrough_rig.dart';

void main() {
  test('opacity 0.8, edge colour (0, 1, 1, 1), contrast 1.25 reach XrPassthroughStyleFB and its BCS struct', () {
    final rig = PassthroughRig()..begin();
    rig.component.setStyle(const MetaPassthroughStyle(
        opacity: 0.8, enableEdgeRendering: true, edgeColorRgba: 0x00FFFFFF, contrast: 1.25));
    final style = rig.recorder.styles.last;
    expect(rig.recorder.calls.last, 'xrPassthroughLayerSetStyleFB');
    expect(style.opacity, closeTo(0.8, 1e-9));
    expect(style.edgeColor, [0.0, 1.0, 1.0, 1.0]);
    expect(style.contrast, 1.25);
    expect(style.brightness, 0.0);
    expect(style.saturation, 1.0);
  });

  test('without edge rendering the edge colour is transparent; the creation style is applied', () {
    final rig = PassthroughRig(
        component: LuminaMetaPassthroughComponent(style: const MetaPassthroughStyle(opacity: 0.5, saturation: 0)))
      ..begin();
    final style = rig.recorder.styles.first;
    expect(style.edgeColor[3], 0.0);
    expect(style.opacity, 0.5);
    expect(style.saturation, 0.0);
  });
}
