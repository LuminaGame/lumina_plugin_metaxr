import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';

void main() {
  group('Meta Social and Performance Tests', () {
    test('MetaFaceBlendshapes contains 63 expressions', () {
      expect(MetaFaceBlendshapes.count, equals(63));
      expect(MetaFaceBlendshapes.mouthSmileL, equals(21));
      expect(MetaFaceBlendshapes.mouthSmileR, equals(22));
      expect(MetaFaceBlendshapes.jawDrop, equals(17));
    });

    test('LuminaMetaFaceTrackingComponent computes smile and jaw metrics', () {
      final comp = LuminaMetaFaceTrackingComponent();
      expect(comp.smileIntensity, equals(0.0));
      expect(comp.jawOpen, equals(0.0));

      comp.expressions.setWeight(MetaFaceBlendshapes.mouthSmileL, 0.8);
      comp.expressions.setWeight(MetaFaceBlendshapes.mouthSmileR, 0.6);
      expect(comp.smileIntensity, closeTo(0.7, 0.001));

      comp.expressions.setWeight(MetaFaceBlendshapes.jawDrop, 0.95);
      expect(comp.jawOpen, closeTo(0.95, 0.001));
    });

    test('MetaPerformanceController negotiates refresh rates and sets foveation levels', () {
      final perf = MetaPerformanceController(deviceModel: MetaQuestDeviceModel.quest3);

      expect(perf.currentRefreshRate, equals(90.0));

      // Quest 3 supports 120Hz
      final switchSuccess = perf.requestRefreshRate(120.0);
      expect(switchSuccess, isTrue);
      expect(perf.currentRefreshRate, equals(120.0));

      // Unsupported rate (e.g. 144Hz) should be rejected
      final invalidSwitch = perf.requestRefreshRate(144.0);
      expect(invalidSwitch, isFalse);
      expect(perf.currentRefreshRate, equals(120.0));

      // Foveation level
      perf.setFoveationLevel(MetaFoveationLevel.highTop, dynamic: true);
      expect(perf.foveationLevel, equals(MetaFoveationLevel.highTop));
      expect(perf.useDynamicFoveation, isTrue);
    });
  });
}
