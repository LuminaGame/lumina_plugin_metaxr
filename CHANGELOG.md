# Changelog

All notable changes to `lumina_plugin_metaxr` will be documented in this file.

## [0.1.0] - 2026-10-02

### Added
- Meta Quest OpenXR SDK plugin for Lumina Studio and Lumina engine, layered on top of `lumina_plugin_openxr`.
- Meta OpenXR extension registry (`XR_FB_*`).
- Mixed reality passthrough layers (`XR_FB_passthrough`) with Reconstruction and ProjectedSurface modes, Underlay/Overlay compositor placement, and edge styling controls via `LuminaMetaPassthroughComponent`.
- 26-joint hand tracking (`XR_FB_hand_tracking_mesh`, `XR_FB_hand_tracking_aim`) with pinch gesture strength detection and procedural hand mesh debug geometry generator via `LuminaMetaHandTrackingComponent`.
- Spatial entities and persistent world anchors (`XR_FB_spatial_entity`) via `LuminaMetaSpatialAnchorComponent`.
- Real-world classified room surfaces (`XR_FB_scene`: Floor, Wall, Ceiling, Table, Couch, Window, Door) via `LuminaMetaScenePlaneComponent`.
- Social tracking: 63 facial expression weights (targeting `XR_FB_face_tracking2`) via `LuminaMetaFaceTrackingComponent` and social eye tracking (`XR_FB_eye_tracking_social`).
- Meta Quest display refresh rate switching (72/80/90/120 Hz) and foveated rendering level management (`MetaPerformanceController`).
- Lumina Studio editor integration: MetaXR settings panel, interactive simulation panel for testing without a headset, and MCP tools `lumina_plugin_metaxr.get_capabilities` and `lumina_plugin_metaxr.simulate_pinch`.
