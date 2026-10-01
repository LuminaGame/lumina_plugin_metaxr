/// The 63 Meta expression blendshape indices defined in XR_FB_face_tracking2.
class MetaFaceBlendshapes {
  static const int count = 63;

  // Brow
  static const int browLowererL = 0;
  static const int browLowererR = 1;
  static const int browInnerUp = 2;
  static const int browOuterUpL = 3;
  static const int browOuterUpR = 4;

  // Eyes & Cheeks
  static const int eyesClosedL = 5;
  static const int eyesClosedR = 6;
  static const int eyesLookDownL = 7;
  static const int eyesLookDownR = 8;
  static const int eyesLookUpL = 9;
  static const int eyesLookUpR = 10;
  static const int cheekPuffL = 11;
  static const int cheekPuffR = 12;
  static const int cheekSuckL = 13;
  static const int cheekSuckR = 14;
  static const int cheekRaiserL = 15;
  static const int cheekRaiserR = 16;

  // Jaw & Mouth
  static const int jawDrop = 17;
  static const int jawSidewaysLeft = 18;
  static const int jawSidewaysRight = 19;
  static const int jawThrust = 20;
  static const int mouthSmileL = 21;
  static const int mouthSmileR = 22;
  static const int mouthFrownL = 23;
  static const int mouthFrownR = 24;
  static const int mouthPucker = 25;
  static const int mouthWiden = 26;
  static const int mouthDimpleL = 27;
  static const int mouthDimpleR = 28;
  static const int lipCornerPullerL = 29;
  static const int lipCornerPullerR = 30;
  static const int lipTightenerL = 31;
  static const int lipTightenerR = 32;
  static const int upperLipRaiserL = 33;
  static const int upperLipRaiserR = 34;
  static const int lowerLipDepressorL = 35;
  static const int lowerLipDepressorR = 36;
}

/// Container for 63 real-time facial expression weights [0.0..1.0].
class MetaFaceExpressionWeights {
  final List<double> weights = List.filled(MetaFaceBlendshapes.count, 0.0);
  final List<double> confidences = List.filled(MetaFaceBlendshapes.count, 0.0);
  bool isValid = false;

  double getWeight(int blendshapeIndex) {
    if (blendshapeIndex < 0 || blendshapeIndex >= MetaFaceBlendshapes.count) return 0.0;
    return weights[blendshapeIndex];
  }

  void setWeight(int blendshapeIndex, double val) {
    if (blendshapeIndex >= 0 && blendshapeIndex < MetaFaceBlendshapes.count) {
      weights[blendshapeIndex] = val.clamp(0.0, 1.0);
    }
  }
}
