import 'package:vector_math/vector_math_64.dart';

/// Social eye tracking data from Meta Quest Pro (`XR_FB_eye_tracking_social`).
class MetaEyeTrackingData {
  bool isGazeValid = false;
  final Vector3 leftGazeDirection = Vector3(1.0, 0.0, 0.0);
  final Vector3 rightGazeDirection = Vector3(1.0, 0.0, 0.0);
  double leftPupilDiameterMm = 3.5;
  double rightPupilDiameterMm = 3.5;

  /// Combined convergence gaze direction vector.
  Vector3 get combinedGazeDirection =>
      (leftGazeDirection + rightGazeDirection).normalized();
}
