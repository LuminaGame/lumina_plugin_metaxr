import 'package:vector_math/vector_math_64.dart';

/// Represents a persistent physical spatial anchor tracked by Meta Quest (`XR_FB_spatial_entity`).
class MetaSpatialAnchor {
  final String uuid;
  bool isLocalized;
  final Vector3 location;
  final Quaternion rotation;
  final DateTime createdAt;

  MetaSpatialAnchor({
    required this.uuid,
    this.isLocalized = false,
    Vector3? location,
    Quaternion? rotation,
    DateTime? createdAt,
  })  : location = location ?? Vector3.zero(),
        rotation = rotation ?? Quaternion.identity(),
        createdAt = createdAt ?? DateTime.now();

  /// Updates anchor pose upon relocalization.
  void updatePose(Vector3 newLocation, Quaternion newRotation) {
    location.setFrom(newLocation);
    rotation.setFrom(newRotation);
    isLocalized = true;
  }
}
