import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';

void main() {
  group('Meta Extensions and Device Profiles Tests', () {
    test('MetaOpenXrExtensions strings match Meta-OpenXR-SDK specification', () {
      expect(MetaOpenXrExtensions.passthrough, equals('XR_FB_passthrough'));
      expect(MetaOpenXrExtensions.handTrackingMesh, equals('XR_FB_hand_tracking_mesh'));
      expect(MetaOpenXrExtensions.handTrackingAim, equals('XR_FB_hand_tracking_aim'));
      expect(MetaOpenXrExtensions.spatialEntity, equals('XR_FB_spatial_entity'));
      expect(MetaOpenXrExtensions.scene, equals('XR_FB_scene'));
      expect(MetaOpenXrExtensions.faceTracking2, equals('XR_FB_face_tracking2'));
      expect(MetaOpenXrExtensions.eyeTrackingSocial, equals('XR_FB_eye_tracking_social'));
      expect(MetaOpenXrExtensions.displayRefreshRate, equals('XR_FB_display_refresh_rate'));
      expect(MetaOpenXrExtensions.foveation, equals('XR_FB_foveation'));
    });

    test('MetaQuestDeviceModel reports accurate hardware capability flags', () {
      // Quest 2 has monochrome IR passthrough, no face/eye tracking
      expect(MetaQuestDeviceModel.quest2.hasColorPassthrough, isFalse);
      expect(MetaQuestDeviceModel.quest2.hasFaceTracking, isFalse);
      expect(MetaQuestDeviceModel.quest2.hasEyeTracking, isFalse);
      expect(MetaQuestDeviceModel.quest2.supportedRefreshRates, contains(120.0));

      // Quest Pro has color passthrough, face and eye tracking
      expect(MetaQuestDeviceModel.questPro.hasColorPassthrough, isTrue);
      expect(MetaQuestDeviceModel.questPro.hasFaceTracking, isTrue);
      expect(MetaQuestDeviceModel.questPro.hasEyeTracking, isTrue);
      expect(MetaQuestDeviceModel.questPro.hasSceneMesh, isFalse);

      // Quest 3 has color passthrough, active scene depth mesh, but no eye/face cameras
      expect(MetaQuestDeviceModel.quest3.hasColorPassthrough, isTrue);
      expect(MetaQuestDeviceModel.quest3.hasSceneMesh, isTrue);
      expect(MetaQuestDeviceModel.quest3.hasFaceTracking, isFalse);
      expect(MetaQuestDeviceModel.quest3.hasEyeTracking, isFalse);
      expect(MetaQuestDeviceModel.quest3.supportedRefreshRates, contains(90.0));
      expect(MetaQuestDeviceModel.quest3.supportedRefreshRates, contains(120.0));
    });
  });
}
