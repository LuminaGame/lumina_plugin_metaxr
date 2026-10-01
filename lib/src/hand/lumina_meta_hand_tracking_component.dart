import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
import 'meta_hand_pose.dart';

/// Scene component tracking Meta Quest hand gestures, 26 joints, and pinch states.
class LuminaMetaHandTrackingComponent extends LuminaSceneComponent {
  final LuminaXRHand hand;
  late final MetaHandPose currentPose;

  LuminaMetaHandTrackingComponent({
    super.key,
    required this.hand,
    super.location,
    super.rotation,
  }) {
    currentPose = MetaHandPose(hand: hand);
  }

  /// Whether this hand is currently tracked by the headset cameras.
  bool get isTracked => currentPose.isTracked;

  /// Whether the user is pinching with the index finger.
  bool get isIndexPinching => currentPose.pinch.isIndexPinching;

  /// Index finger pinch strength [0.0..1.0].
  double get indexPinchStrength => currentPose.pinch.indexStrength;
}
