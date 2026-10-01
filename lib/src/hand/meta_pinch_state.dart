/// Tracks pinch gesture strength [0.0..1.0] and threshold flags for each finger.
class MetaPinchState {
  static const double defaultPinchThreshold = 0.70;

  double indexStrength = 0.0;
  double middleStrength = 0.0;
  double ringStrength = 0.0;
  double littleStrength = 0.0;

  double pinchThreshold = defaultPinchThreshold;

  bool get isIndexPinching => indexStrength >= pinchThreshold;
  bool get isMiddlePinching => middleStrength >= pinchThreshold;
  bool get isRingPinching => ringStrength >= pinchThreshold;
  bool get isLittlePinching => littleStrength >= pinchThreshold;

  /// Returns true if any finger is currently pinching with the thumb.
  bool get isAnyPinching =>
      isIndexPinching || isMiddlePinching || isRingPinching || isLittlePinching;

  void update({
    double index = 0.0,
    double middle = 0.0,
    double ring = 0.0,
    double little = 0.0,
  }) {
    indexStrength = index.clamp(0.0, 1.0);
    middleStrength = middle.clamp(0.0, 1.0);
    ringStrength = ring.clamp(0.0, 1.0);
    littleStrength = little.clamp(0.0, 1.0);
  }
}
