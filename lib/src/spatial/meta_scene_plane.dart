import 'package:vector_math/vector_math_64.dart';

/// Semantic classification labels for physical surfaces recognized by Meta Quest Scene API.
enum MetaSemanticLabel {
  floor('Floor'),
  ceiling('Ceiling'),
  wallFace('Wall'),
  table('Table'),
  couch('Couch'),
  doorFrame('Door'),
  windowFrame('Window'),
  other('Other');

  final String displayName;
  const MetaSemanticLabel(this.displayName);
}

/// Represents a classified 2D planar surface in the user's physical room (`XR_FB_scene`).
class MetaScenePlane {
  final String id;
  final MetaSemanticLabel label;
  final Vector3 center;
  final Vector2 size; // width, height (cm)
  final Vector3 normal;
  final List<Vector2> boundaryPolygon;

  MetaScenePlane({
    required this.id,
    required this.label,
    required this.center,
    required this.size,
    required this.normal,
    this.boundaryPolygon = const [],
  });

  /// Computes approximate surface area in square meters.
  double get areaSquareMeters => (size.x * size.y) / 10000.0;
}
