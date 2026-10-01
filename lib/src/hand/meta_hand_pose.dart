import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
import 'package:vector_math/vector_math_64.dart';
import 'meta_hand_joint.dart';
import 'meta_pinch_state.dart';

/// Complete tracking snapshot for a hand, including all 26 joint poses and pinch states.
class MetaHandPose {
  final LuminaXRHand hand;
  bool isTracked = false;
  double confidence = 0.0;

  final Map<MetaHandJoint, Vector3> jointLocations = {};
  final Map<MetaHandJoint, Quaternion> jointRotations = {};
  final Map<MetaHandJoint, double> jointRadii = {};

  final MetaPinchState pinch = MetaPinchState();

  // Pointer ray / Aim pose
  final Vector3 aimOrigin = Vector3.zero();
  final Vector3 aimDirection = Vector3(1.0, 0.0, 0.0); // +X forward

  MetaHandPose({required this.hand}) {
    // Populate default joint transforms
    for (final joint in MetaHandJoint.values) {
      jointLocations[joint] = Vector3.zero();
      jointRotations[joint] = Quaternion.identity();
      jointRadii[joint] = 0.01; // 1 cm default joint radius
    }
  }

  /// Calculates distance between thumb tip and specified finger tip in centimeters.
  double getDistanceToThumbTip(MetaHandJoint fingerTip) {
    final thumbPos = jointLocations[MetaHandJoint.thumbTip];
    final fingerPos = jointLocations[fingerTip];
    if (thumbPos == null || fingerPos == null) return double.infinity;
    return thumbPos.distanceTo(fingerPos);
  }

  /// Recalculates pinch strengths based on physical joint distances.
  void computePinchFromDistances() {
    const minDistanceCm = 1.5; // Touch distance
    const maxDistanceCm = 8.0; // Open distance

    double calcStrength(MetaHandJoint tip) {
      final dist = getDistanceToThumbTip(tip);
      if (dist <= minDistanceCm) return 1.0;
      if (dist >= maxDistanceCm) return 0.0;
      return 1.0 - ((dist - minDistanceCm) / (maxDistanceCm - minDistanceCm));
    }

    pinch.update(
      index: calcStrength(MetaHandJoint.indexTip),
      middle: calcStrength(MetaHandJoint.middleTip),
      ring: calcStrength(MetaHandJoint.ringTip),
      little: calcStrength(MetaHandJoint.littleTip),
    );
  }
}
