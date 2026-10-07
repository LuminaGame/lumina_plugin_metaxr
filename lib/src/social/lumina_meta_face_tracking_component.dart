import 'package:lumina/lumina.dart';
import 'package:lumina_plugin_metaxr/src/social/meta_face_tracking.dart';

/// Component driving facial blendshape morph targets from Meta Quest face tracking.
class LuminaMetaFaceTrackingComponent extends LuminaActorComponent {
  final MetaFaceExpressionWeights expressions = MetaFaceExpressionWeights();
  bool isEnabled = true;

  LuminaMetaFaceTrackingComponent({super.key});

  /// Evaluates smile intensity (average of left and right smile weights).
  double get smileIntensity =>
      (expressions.getWeight(MetaFaceBlendshapes.mouthSmileL) +
          expressions.getWeight(MetaFaceBlendshapes.mouthSmileR)) /
      2.0;

  /// Evaluates jaw opening percentage [0.0..1.0].
  double get jawOpen => expressions.getWeight(MetaFaceBlendshapes.jawDrop);
}
