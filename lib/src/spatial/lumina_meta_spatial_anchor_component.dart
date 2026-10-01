import 'package:lumina/lumina.dart';
import 'meta_spatial_anchor.dart';

/// Scene component pinning its owner actor to a physical world anchor.
class LuminaMetaSpatialAnchorComponent extends LuminaSceneComponent {
  MetaSpatialAnchor? anchor;

  LuminaMetaSpatialAnchorComponent({
    super.key,
    this.anchor,
    super.location,
    super.rotation,
  }) {
    if (anchor != null) {
      applyAnchorPose();
    }
  }

  /// Binds this component to a new spatial anchor.
  void bindAnchor(MetaSpatialAnchor newAnchor) {
    anchor = newAnchor;
    applyAnchorPose();
  }

  /// Synchronizes local location and rotation from the bound anchor.
  void applyAnchorPose() {
    final a = anchor;
    if (a != null && a.isLocalized) {
      location = a.location;
      rotation = a.rotation;
    }
  }
}
