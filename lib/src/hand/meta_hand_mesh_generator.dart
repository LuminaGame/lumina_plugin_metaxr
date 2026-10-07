import 'package:vector_math/vector_math_64.dart';
import 'package:lumina_plugin_metaxr/src/hand/meta_hand_joint.dart';
import 'package:lumina_plugin_metaxr/src/hand/meta_hand_pose.dart';

/// Generates procedural visualization geometry for tracked hand joints.
class MetaHandMeshGenerator {
  /// Builds simple joint box/capsule vertices around tracked joint positions.
  static ({List<Vector3> positions, List<Vector3> normals, List<int> indices}) generateHandDebugGeometry(
      MetaHandPose pose) {
    final positions = <Vector3>[];
    final normals = <Vector3>[];
    final indices = <int>[];

    // For each joint, create a small diamond/cube
    for (final joint in MetaHandJoint.values) {
      final center = pose.jointLocations[joint] ?? Vector3.zero();
      final radius = pose.jointRadii[joint] ?? 0.01;

      final baseIndex = positions.length;

      // 6 diamond vertices around joint center
      positions.add(center + Vector3(radius, 0.0, 0.0));
      positions.add(center + Vector3(-radius, 0.0, 0.0));
      positions.add(center + Vector3(0.0, radius, 0.0));
      positions.add(center + Vector3(0.0, -radius, 0.0));
      positions.add(center + Vector3(0.0, 0.0, radius));
      positions.add(center + Vector3(0.0, 0.0, -radius));

      for (var i = 0; i < 6; i++) {
        normals.add(Vector3(0.0, 0.0, 1.0));
      }

      // Triangles forming octahedron
      indices.addAll([
        baseIndex + 0, baseIndex + 2, baseIndex + 4,
        baseIndex + 2, baseIndex + 1, baseIndex + 4,
        baseIndex + 1, baseIndex + 3, baseIndex + 4,
        baseIndex + 3, baseIndex + 0, baseIndex + 4,
        baseIndex + 2, baseIndex + 0, baseIndex + 5,
        baseIndex + 1, baseIndex + 2, baseIndex + 5,
        baseIndex + 3, baseIndex + 1, baseIndex + 5,
        baseIndex + 0, baseIndex + 3, baseIndex + 5,
      ]);
    }

    return (positions: positions, normals: normals, indices: indices);
  }
}
