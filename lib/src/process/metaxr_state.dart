import 'package:lumina_plugin_openxr/xr_types.dart' show LuminaXRHand;

import 'package:lumina_plugin_metaxr/src/hand/meta_hand_pose.dart';
import 'package:lumina_plugin_metaxr/src/meta_device.dart';
import 'package:lumina_plugin_metaxr/src/passthrough/meta_passthrough_style.dart';
import 'package:lumina_plugin_metaxr/src/performance/meta_performance_controller.dart';

/// The fingers a pinch can be simulated on, in display order.
const List<String> kMetaPinchFingers = ['index', 'middle', 'ring', 'little'];

/// The editor-side simulation state of MetaXR Support: the target device and
/// its display settings, both simulated hands and the passthrough style. It
/// lives in the plugin process; the declarative panels, the MCP tools and the
/// channel all read and change this one copy.
class MetaXrState {
  MetaXrState();

  final MetaPerformanceController performance = MetaPerformanceController();
  final MetaHandPose leftHand = MetaHandPose(hand: LuminaXRHand.left);
  final MetaHandPose rightHand = MetaHandPose(hand: LuminaXRHand.right);
  MetaPassthroughStyle passthroughStyle = const MetaPassthroughStyle();

  /// The hand the simulation panel drives.
  LuminaXRHand simulatedHand = LuminaXRHand.right;

  MetaHandPose hand(LuminaXRHand hand) => hand == LuminaXRHand.left ? leftHand : rightHand;

  /// Switches the target device; keeps the refresh rate when the new device
  /// supports it, else falls back to the device's first rate.
  void selectDevice(MetaQuestDeviceModel device) {
    final rate = performance.currentRefreshRate;
    performance.deviceModel = device;
    performance.requestRefreshRate(device.supportedRefreshRates.contains(rate) ? rate : device.supportedRefreshRates.first);
  }

  /// Sets one finger's pinch strength on [hand], keeping the other fingers.
  /// Throws an [ArgumentError] for an unknown finger.
  void setPinch(LuminaXRHand hand, String finger, double strength) {
    final p = this.hand(hand).pinch;
    if (!kMetaPinchFingers.contains(finger)) throw ArgumentError.value(finger, 'finger', 'not one of $kMetaPinchFingers');
    p.update(
      index: finger == 'index' ? strength : p.indexStrength,
      middle: finger == 'middle' ? strength : p.middleStrength,
      ring: finger == 'ring' ? strength : p.ringStrength,
      little: finger == 'little' ? strength : p.littleStrength,
    );
  }

  /// [finger]'s pinch strength on [hand].
  double pinchOf(LuminaXRHand hand, String finger) {
    final p = this.hand(hand).pinch;
    return switch (finger) {
      'index' => p.indexStrength,
      'middle' => p.middleStrength,
      'ring' => p.ringStrength,
      _ => p.littleStrength,
    };
  }

  /// The device and its capabilities, as the `get_capabilities` MCP tool
  /// returns them.
  Map<String, Object?> capabilitiesJson() {
    final d = performance.deviceModel;
    return {
      'device_model': d.displayName,
      'color_passthrough': d.hasColorPassthrough,
      'face_tracking': d.hasFaceTracking,
      'eye_tracking': d.hasEyeTracking,
      'scene_mesh': d.hasSceneMesh,
      'refresh_rate_hz': performance.currentRefreshRate,
      'foveation_level': performance.foveationLevel.name,
    };
  }

  Map<String, Object?> _handJson(LuminaXRHand h) => {
        for (final f in kMetaPinchFingers) f: pinchOf(h, f),
        'is_pinching': hand(h).pinch.isAnyPinching,
      };

  /// Everything above as JSON (the channel's `getState` answer and the
  /// `stateChanged` event).
  Map<String, Object?> toJson() => {
        'device': performance.deviceModel.name,
        ...capabilitiesJson(),
        'supported_refresh_rates': performance.deviceModel.supportedRefreshRates,
        'dynamic_foveation': performance.useDynamicFoveation,
        'simulated_hand': simulatedHand.name,
        'hands': {'left': _handJson(LuminaXRHand.left), 'right': _handJson(LuminaXRHand.right)},
        'passthrough': {
          'edge_rendering': passthroughStyle.enableEdgeRendering,
          'edge_contrast': passthroughStyle.edgeContrast,
        },
      };
}
