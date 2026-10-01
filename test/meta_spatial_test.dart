import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Meta Spatial Anchors and Scene Tests', () {
    test('MetaSpatialAnchor initializes and updates localization pose', () {
      final anchor = MetaSpatialAnchor(uuid: 'anchor-guid-1234');
      expect(anchor.uuid, equals('anchor-guid-1234'));
      expect(anchor.isLocalized, isFalse);

      anchor.updatePose(Vector3(50.0, 100.0, 20.0), Quaternion.identity());
      expect(anchor.isLocalized, isTrue);
      expect(anchor.location.x, closeTo(50.0, 0.001));
      expect(anchor.location.y, closeTo(100.0, 0.001));
    });

    test('LuminaMetaSpatialAnchorComponent synchronizes pose with localized anchor', () {
      final anchor = MetaSpatialAnchor(
        uuid: 'anchor-5678',
        isLocalized: true,
        location: Vector3(120.0, 0.0, 80.0),
      );

      final comp = LuminaMetaSpatialAnchorComponent(anchor: anchor);
      expect(comp.location.x, closeTo(120.0, 0.001));
      expect(comp.location.z, closeTo(80.0, 0.001));

      anchor.updatePose(Vector3(200.0, 0.0, 90.0), Quaternion.identity());
      comp.applyAnchorPose();
      expect(comp.location.x, closeTo(200.0, 0.001));
    });

    test('MetaScenePlane calculates area and maps semantic labels', () {
      final plane = MetaScenePlane(
        id: 'plane-floor-1',
        label: MetaSemanticLabel.floor,
        center: Vector3(0.0, 0.0, 0.0),
        size: Vector2(300.0, 400.0), // 300cm x 400cm = 12 m^2
        normal: Vector3(0.0, 0.0, 1.0),
      );

      expect(plane.label, equals(MetaSemanticLabel.floor));
      expect(plane.areaSquareMeters, closeTo(12.0, 0.01));

      final planeComp = LuminaMetaScenePlaneComponent(plane: plane);
      expect(planeComp.label, equals(MetaSemanticLabel.floor));
    });
  });
}
