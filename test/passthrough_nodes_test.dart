import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_metaxr/runtime.dart';

import 'support/passthrough_rig.dart';

void main() {
  tearDown(MetaPassthroughNodes.unregister);

  test('the passthrough nodes drive the world\'s passthrough component', () {
    MetaPassthroughNodes.register();
    final rig = PassthroughRig()..begin();
    final world = LuminaWorld(worldType: LuminaWorldType.game);
    final holder = LuminaActor()..addComponent(rig.component);
    final self = LuminaActor();
    world.persistentLevel
      ..registerActor(holder)
      ..registerActor(self);
    final ctx = LuminaBlueprintCallContext(self);
    LuminaBlueprintFunction call(String id) => LuminaBlueprintFunctionRegistry.function(id)!;

    expect(call(MetaPassthroughNodes.isAvailableId)(ctx, const {})['return_value'], isTrue);
    rig.recorder.calls.clear();
    call(MetaPassthroughNodes.setEnabledId)(ctx, {'enabled': false});
    expect(rig.recorder.calls, ['xrPassthroughLayerPauseFB']);
    call(MetaPassthroughNodes.setStyleId)(ctx, {
      'opacity': 0.7,
      'edge_color': [1.0, 0.0, 1.0, 1.0],
      'brightness': 10.0,
      'contrast': 1.1,
      'saturation': 0.5,
    });
    final style = rig.recorder.styles.last;
    expect(style.opacity, closeTo(0.7, 1e-9));
    expect(style.edgeColor, [1.0, 0.0, 1.0, 1.0]);
    expect(style.brightness, 10.0);
    expect(style.saturation, 0.5);
  });

  test('a Quest build declares the passthrough feature', () {
    expect(MetaPassthroughManifest.usesFeature(required: true),
        '<uses-feature android:name="com.oculus.feature.PASSTHROUGH" android:required="true"/>');
  });
}
