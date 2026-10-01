import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';
import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Meta Hand Tracking Tests', () {
    test('MetaHandJoint contains 26 joints with distinct indices', () {
      expect(MetaHandJoint.values.length, equals(26));
      expect(MetaHandJoint.palm.index, equals(0));
      expect(MetaHandJoint.wrist.index, equals(1));
      expect(MetaHandJoint.thumbTip.index, equals(5));
      expect(MetaHandJoint.littleTip.index, equals(25));

      expect(MetaHandJoint.indexTip.isTip, isTrue);
      expect(MetaHandJoint.wrist.isTip, isFalse);
    });

    test('MetaPinchState detects individual and combined finger pinches', () {
      final pinch = MetaPinchState();
      expect(pinch.isAnyPinching, isFalse);

      pinch.update(index: 0.85);
      expect(pinch.isIndexPinching, isTrue);
      expect(pinch.isMiddlePinching, isFalse);
      expect(pinch.isAnyPinching, isTrue);

      pinch.update(index: 0.20, middle: 0.95);
      expect(pinch.isIndexPinching, isFalse);
      expect(pinch.isMiddlePinching, isTrue);
    });

    test('MetaHandPose calculates pinch strengths from joint distances', () {
      final pose = MetaHandPose(hand: LuminaXRHand.right);

      // Set thumb tip and index tip close (1.0 cm apart)
      pose.jointLocations[MetaHandJoint.thumbTip] = Vector3(0.0, 0.0, 0.0);
      pose.jointLocations[MetaHandJoint.indexTip] = Vector3(0.0, 0.0, 1.0); // 1.0 cm
      pose.jointLocations[MetaHandJoint.middleTip] = Vector3(0.0, 0.0, 10.0); // 10.0 cm

      pose.computePinchFromDistances();

      expect(pose.pinch.indexStrength, closeTo(1.0, 0.01));
      expect(pose.pinch.isIndexPinching, isTrue);
      expect(pose.pinch.middleStrength, closeTo(0.0, 0.01));
      expect(pose.pinch.isMiddlePinching, isFalse);
    });

    test('MetaHandMeshGenerator produces valid geometry for all 26 joints', () {
      final pose = MetaHandPose(hand: LuminaXRHand.left);
      final mesh = MetaHandMeshGenerator.generateHandDebugGeometry(pose);

      // 26 joints * 6 vertices = 156 vertices
      expect(mesh.positions.length, equals(26 * 6));
      expect(mesh.normals.length, equals(mesh.positions.length));
      // 26 joints * 8 triangles * 3 indices = 624 indices
      expect(mesh.indices.length, equals(26 * 24));
    });
  });
}
