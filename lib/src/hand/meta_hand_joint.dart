/// The 26 OpenXR hand tracking joints according to XR_EXT_hand_tracking and Meta OpenXR SDK.
enum MetaHandJoint {
  palm,
  wrist,

  // Thumb
  thumbMetacarpal,
  thumbProximal,
  thumbDistal,
  thumbTip,

  // Index
  indexMetacarpal,
  indexProximal,
  indexIntermediate,
  indexDistal,
  indexTip,

  // Middle
  middleMetacarpal,
  middleProximal,
  middleIntermediate,
  middleDistal,
  middleTip,

  // Ring
  ringMetacarpal,
  ringProximal,
  ringIntermediate,
  ringDistal,
  ringTip,

  // Little
  littleMetacarpal,
  littleProximal,
  littleIntermediate,
  littleDistal,
  littleTip;

  /// Whether this joint is the tip of any finger.
  bool get isTip =>
      this == thumbTip ||
      this == indexTip ||
      this == middleTip ||
      this == ringTip ||
      this == littleTip;
}
