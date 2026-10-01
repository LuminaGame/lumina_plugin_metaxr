# MetaXR Plugin for Lumina Studio (`lumina_plugin_metaxr`)

Meta Quest OpenXR SDK extension plugin for Lumina game engine and Lumina Studio. Builds directly upon `lumina_plugin_openxr` to expose Meta-specific OpenXR extensions (`XR_FB_*` and `XR_META_*`).

## Features

- **Mixed Reality Passthrough**: Full-color passthrough underlay and overlay layers (`XR_FB_passthrough`), edge rendering styling, and color adjustment via `LuminaMetaPassthroughComponent`.
- **26-Joint Hand Tracking**: Full 26-joint hand skeleton tracking (`XR_FB_hand_tracking_mesh`, `XR_FB_hand_tracking_aim`) with per-finger pinch strength detection and procedural hand mesh visualization via `LuminaMetaHandTrackingComponent`.
- **Spatial Anchors & Entities**: Pin any Lumina actor to real-world persistent spatial anchors (`XR_FB_spatial_entity`) via `LuminaMetaSpatialAnchorComponent`.
- **Room Scene Perception**: Semantic room surface classification (`XR_FB_scene`: Floor, Ceiling, Wall, Table, Couch, Window, Door) with collision/boundary generation via `LuminaMetaScenePlaneComponent`.
- **Face & Eye Tracking**: 63 Meta expression blendshapes (`XR_FB_face_tracking2`) driving morph targets on MetaHuman and character skeletal meshes, plus social gaze tracking (`XR_FB_eye_tracking_social`).
- **Quest Performance & Display**: Display refresh rate switching (72Hz, 80Hz, 90Hz, 120Hz) and fixed/dynamic foveated rendering levels via `MetaPerformanceController`.
- **Editor & Simulation Tools**: MetaXR settings form, in-editor hand gesture and passthrough simulation panel, and MCP tools (`metaxr.get_capabilities`, `metaxr.simulate_pinch`).

## Installation

Add to your project's `pubspec.yaml` or enable via **Plugins → Plugin Manager**:

```yaml
dependencies:
  lumina_plugin_openxr:
    path: ../openxr
  lumina_plugin_metaxr:
    path: ../metaxr
```

## Architecture

- `lib/src/meta_extensions.dart`: Catalog of Meta OpenXR extension strings.
- `lib/src/meta_device.dart`: Hardware profiles (Quest 2, Quest Pro, Quest 3, Quest 3S).
- `lib/src/passthrough/`: Passthrough styles, layers, and `LuminaMetaPassthroughComponent`.
- `lib/src/hand/`: 26-joint hierarchy, pinch detector, mesh generator, and `LuminaMetaHandTrackingComponent`.
- `lib/src/spatial/`: Spatial anchors, semantic room planes, and components.
- `lib/src/social/`: 63 expression blendshapes, gaze tracking, and `LuminaMetaFaceTrackingComponent`.
- `lib/src/performance/`: Display refresh rates and foveation controls.
- `lib/src/ui/`: shadcn_flutter settings and simulation panels.

## License

MIT License. See [LICENSE](file:///d:/lumina/metaxr/LICENSE).
