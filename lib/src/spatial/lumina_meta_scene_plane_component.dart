import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_metaxr/src/spatial/meta_scene_plane.dart';

/// Scene component representing a physical scanned room surface (floor, walls, desk).
class LuminaMetaScenePlaneComponent extends LuminaSceneComponent {
  final MetaScenePlane plane;

  LuminaMetaScenePlaneComponent({
    super.key,
    required this.plane,
    super.location,
    super.rotation,
  }) {
    location = plane.center;
  }

  MetaSemanticLabel get label => plane.label;
}
