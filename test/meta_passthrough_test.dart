import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';

void main() {
  group('Meta Passthrough Tests', () {
    test('MetaPassthroughStyle properties and copyWith operate properly', () {
      const style = MetaPassthroughStyle();
      expect(style.opacity, equals(1.0));
      expect(style.enableEdgeRendering, isFalse);

      final styled = style.copyWith(
        opacity: 0.8,
        enableEdgeRendering: true,
        edgeColorRgba: 0xFF00FFFF,
      );

      expect(styled.opacity, closeTo(0.8, 0.001));
      expect(styled.enableEdgeRendering, isTrue);
      expect(styled.edgeColorRgba, equals(0xFF00FFFF));
    });

    test('MetaPassthroughLayer manages lifecycle transitions', () {
      final layer = MetaPassthroughLayer(
        placement: MetaPassthroughPlacement.underlay,
      );

      expect(layer.state, equals(MetaPassthroughState.uninitialized));
      expect(layer.isRunning, isFalse);

      layer.start();
      expect(layer.state, equals(MetaPassthroughState.running));
      expect(layer.isRunning, isTrue);

      layer.pause();
      expect(layer.state, equals(MetaPassthroughState.paused));
      expect(layer.isRunning, isFalse);

      layer.resume();
      expect(layer.state, equals(MetaPassthroughState.running));

      layer.destroy();
      expect(layer.state, equals(MetaPassthroughState.destroyed));
    });

    test('LuminaMetaPassthroughComponent toggles layer state and updates style', () {
      final comp = LuminaMetaPassthroughComponent(isEnabled: true);
      expect(comp.isEnabled, isTrue);
      expect(comp.layer.isRunning, isTrue);

      comp.setEnabled(false);
      expect(comp.isEnabled, isFalse);
      expect(comp.layer.isRunning, isFalse);

      comp.setStyle(const MetaPassthroughStyle(opacity: 0.5));
      expect(comp.layer.style.opacity, closeTo(0.5, 0.001));
    });
  });
}
