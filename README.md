# MetaXR Support — Lumina Studio plugin (`lumina_plugin_metaxr`)

Meta Quest features for the [Lumina](https://github.com/LuminaGame/lumina) game engine and its editor, Lumina
Studio, built on the Khronos OpenXR base plugin
[`lumina_plugin_openxr`](https://github.com/LuminaGame/lumina_plugin_openxr). It models the Meta OpenXR extensions
(`XR_FB_*`) as Lumina components and Dart types: mixed reality passthrough, 26-joint hand tracking with pinch
gestures, spatial anchors, scene planes, face and eye tracking, and the Quest display and foveation settings, with
an editor panel that simulates them without a headset.

*Türkçe: [README.tr.md](README.tr.md)*

## Contents

- [Status](#status)
- [How it fits](#how-it-fits)
- [Features](#features)
- [Requirements and platforms](#requirements-and-platforms)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Editor integration](#editor-integration)
- [Runs in its own process](#runs-in-its-own-process)
- [Working without a headset](#working-without-a-headset)
- [Architecture](#architecture)
- [Coordinate systems and units](#coordinate-systems-and-units)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Limitations and roadmap](#limitations-and-roadmap)
- [Contributing](#contributing)
- [License](#license)

## Status

Version 0.2.0. This release is the **Dart layer**: the extension catalogue, the device profiles, the data model of
every feature, the scene components, the pinch logic, the debug hand geometry, the editor panels and the MCP tools,
all tested. None of the `XR_FB_*` functions is called yet: the OpenXR base plugin does not create an OpenXR
instance or session yet (see its README), so passthrough layers, hand joints, anchors, scene planes and face weights
are filled by your code, by the editor's simulation panel or by MCP, not by the headset.

| Area | Data model and components | Fed by the runtime |
|---|---|---|
| Passthrough (`XR_FB_passthrough`) | done | planned |
| Hand tracking, 26 joints, pinch (`XR_EXT_hand_tracking` + `XR_FB_hand_tracking_*`) | done | planned |
| Spatial anchors (`XR_FB_spatial_entity`, storage, sharing) | done | planned |
| Scene planes (`XR_FB_scene`, `XR_FB_scene_capture`) | done | planned |
| Face tracking, eye gaze (`XR_FB_face_tracking2`, `XR_FB_eye_tracking_social`) | done | planned |
| Refresh rate and foveation (`XR_FB_display_refresh_rate`, `XR_FB_foveation`) | done (per device profile) | planned |
| Editor settings, simulation panel, MCP tools | done | — |

## How it fits

```
Lumina Studio (lumina_ui) ── loads plugins through lumina_editor_api
        │
lumina_plugin_metaxr   Meta Quest extensions: components, data, editor panels, MCP tools
        │ depends on
lumina_plugin_openxr   OpenXR runtime discovery, loader bridge, session, XR origin/HMD/controllers, stereo, simulator
        │ depends on
lumina + flutter_filament   engine (actors, components) and the Filament renderer
```

The plugin's manifest declares the dependency (`"dependencies": [{"name": "lumina_plugin_openxr", "version": ">=0.1.0"}]`),
and the Plugin Manager checks it when MetaXR Support is enabled. Types from the base plugin, such as `LuminaXRHand`, are used
directly; import both libraries in game code.

## Features

### Extension catalogue

`MetaOpenXrExtensions` holds the extension names the plugin targets, as the Meta OpenXR SDK spells them:

| Group | Extensions |
|---|---|
| Passthrough | `XR_FB_passthrough`, `XR_FB_triangle_mesh` |
| Hands | `XR_FB_hand_tracking_mesh`, `XR_FB_hand_tracking_aim`, `XR_FB_hand_tracking_capsules` |
| Spatial | `XR_FB_spatial_entity`, `XR_FB_spatial_entity_storage`, `XR_FB_spatial_entity_sharing`, `XR_FB_scene`, `XR_FB_scene_capture` |
| Social / body | `XR_FB_face_tracking2`, `XR_FB_eye_tracking_social`, `XR_FB_body_tracking` |
| Performance | `XR_FB_display_refresh_rate`, `XR_FB_foveation`, `XR_FB_swapchain_update_state` |

### Device profiles

`MetaQuestDeviceModel`: `quest2`, `questPro`, `quest3`, `quest3S`, each with `displayName` and the capability flags
the plugin uses: `hasColorPassthrough` (all but Quest 2, whose passthrough is monochrome), `hasEyeTracking` and
`hasFaceTracking` (Quest Pro), `hasSceneMesh` (Quest 3 and 3S) and `supportedRefreshRates` (Quest Pro 72/90 Hz,
the others 72/80/90/120 Hz).

### Passthrough

- `MetaPassthroughLayer`: `purpose` (`MetaPassthroughPurpose.reconstruction` for the full camera view,
  `projectedSurface` for passthrough shown only on given geometry such as a window or portal), `placement`
  (`MetaPassthroughPlacement.underlay` behind the virtual scene, `overlay` in front), `style`, and a lifecycle
  (`start`, `pause`, `resume`, `destroy`; `state`, `isRunning`).
- `MetaPassthroughStyle` (immutable, `copyWith`): `opacity`, `enableEdgeRendering`, `edgeColorRgba`
  (`0x00FF88FF` by default), `edgeContrast`, `brightness`, `contrast`, `saturation`.
- `LuminaMetaPassthroughComponent` (`LuminaSceneComponent`): owns a layer, starts it when enabled;
  `setEnabled(bool)` starts or pauses it, `setStyle(style)` restyles it.

### Hand tracking

- `MetaHandJoint`: the 26 joints of `XR_EXT_hand_tracking` in its order — palm, wrist, then metacarpal, proximal,
  (intermediate,) distal and tip for the thumb, index, middle, ring and little finger; `isTip`.
- `MetaHandPose`: per hand (`LuminaXRHand`), `isTracked`, `confidence`, `jointLocations`, `jointRotations`,
  `jointRadii`, `aimOrigin` / `aimDirection`, and a `MetaPinchState`. `computePinchFromDistances()` derives each
  finger's pinch strength from its tip's distance to the thumb tip: 1.0 at 1.5 cm or closer, 0.0 at 8 cm or more,
  linear between.
- `MetaPinchState`: `indexStrength`, `middleStrength`, `ringStrength`, `littleStrength` (0..1), `pinchThreshold`
  (0.70 by default), `isIndexPinching` … `isLittlePinching`, `isAnyPinching`, `update(...)`.
- `LuminaMetaHandTrackingComponent` (`LuminaSceneComponent`): a hand's `currentPose`, with `isTracked`,
  `isIndexPinching` and `indexPinchStrength` shortcuts.
- `MetaHandMeshGenerator.generateHandDebugGeometry(pose)`: an octahedron per joint, sized by its radius
  (positions, normals, indices; 6 vertices and 8 triangles per joint) for drawing tracked hands while debugging.

### Spatial anchors and scene

- `MetaSpatialAnchor`: `uuid`, `isLocalized`, `location`, `rotation`, `createdAt`; `updatePose(location, rotation)`
  marks it localized.
- `LuminaMetaSpatialAnchorComponent` (`LuminaSceneComponent`): pins its owner to an anchor; `bindAnchor(anchor)`,
  `applyAnchorPose()` copies the anchor's pose once it is localized.
- `MetaScenePlane`: a classified room surface with `id`, `label`, `center`, `size` (width × height in cm), `normal`,
  `boundaryPolygon`, `areaSquareMeters`. `MetaSemanticLabel`: `floor`, `ceiling`, `wallFace`, `table`, `couch`,
  `doorFrame`, `windowFrame`, `other`.
- `LuminaMetaScenePlaneComponent` (`LuminaSceneComponent`): places itself at the plane's centre; `label`.

### Face and eye tracking

- `MetaFaceExpressionWeights`: 63 expression weights and confidences (0..1), `isValid`, `getWeight` / `setWeight`
  (clamped, out-of-range indices ignored). `MetaFaceBlendshapes` names indices for the brows, eyes, cheeks, jaw,
  mouth and lips (`browLowererL`, `eyesClosedL`, `jawDrop`, `mouthSmileL`, …; `count` = 63).
- `LuminaMetaFaceTrackingComponent` (`LuminaActorComponent`): `expressions`, `isEnabled`, and the derived
  `smileIntensity` (mean of both smile weights) and `jawOpen`.
- `MetaEyeTrackingData`: `isGazeValid`, `leftGazeDirection` / `rightGazeDirection`, pupil diameters in mm,
  `combinedGazeDirection`.

### Performance

`MetaPerformanceController`: the target `deviceModel` (Quest 3 by default), `requestRefreshRate(hz)` (accepted only
when the device profile lists it; 90 Hz by default when supported), and `setFoveationLevel(level, dynamic:)` with
`MetaFoveationLevel` `none`, `low`, `medium` (default), `high`, `highTop` and dynamic foveation on by default.

## Requirements and platforms

- Everything `lumina_plugin_openxr` needs (Flutter with Dart `^3.12.0`, the Lumina packages, a C/C++ toolchain for
  the base plugin's Native Assets hook). This plugin has no native code of its own.
- The Dart layer runs wherever Lumina runs (Windows, Linux, macOS, Android); it needs no headset.
- For the features to come from a device later: a Meta Quest (Quest 2, Pro, 3 or 3S) through Quest Link on Windows,
  or a standalone Android build, with the matching features turned on in the headset (hand tracking, passthrough,
  Space Setup for scene data, and face/eye tracking permissions on Quest Pro).
- A Quest Android build declares the VR launcher category and the features it uses in `AndroidManifest.xml`, for
  example:

  ```xml
  <uses-feature android:name="android.hardware.vr.headtracking" android:required="false" />
  <uses-feature android:name="com.oculus.feature.PASSTHROUGH" android:required="false" />
  <!-- in the launcher activity's intent filter -->
  <category android:name="com.oculus.intent.category.VR" />
  ```

  Hand tracking, scene, anchor and face/eye tracking features and permissions follow Meta's documentation for each
  extension once the runtime path is in place.

## Installation

### As a Lumina Studio plugin

1. Install [`lumina_plugin_openxr`](https://github.com/LuminaGame/lumina_plugin_openxr) first.
2. Clone this repository and link or copy it into `<project>/plugins/` or the per-user plugin folder
   (`~/.local/share/lumina/plugins/` on Linux, `%LOCALAPPDATA%\Lumina\plugins` on Windows), or use
   **Plugins → Plugin Manager → Import from Folder**.
3. Enable **MetaXR Support** (category *Virtual Reality*) in the Plugin Manager and restart the editor when it asks.

See [Editor plugins](https://github.com/LuminaGame/lumina/blob/main/docs/en/plugins/index.md) in the Lumina docs.

### As a dependency of a game or another plugin

```yaml
dependencies:
  lumina_plugin_openxr:
    git:
      url: https://github.com/LuminaGame/lumina_plugin_openxr.git
      ref: <commit sha>
  lumina_plugin_metaxr:
    git:
      url: https://github.com/LuminaGame/lumina_plugin_metaxr.git
      ref: <commit sha>
```

```dart
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';
import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
```

For development against local checkouts, a gitignored `pubspec_overrides.yaml` can point `lumina_plugin_openxr` at
`../openxr` and the Lumina packages at `../lumina/...`, `../tools/...`; link the shared Filament build as
`filament`.

## Quick start

```dart
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';
import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
import 'package:vector_math/vector_math_64.dart'; // Vector3, Quaternion in the examples below

final origin = LuminaXROriginActor();

final passthrough = LuminaMetaPassthroughComponent(
  placement: MetaPassthroughPlacement.underlay,
  style: const MetaPassthroughStyle(enableEdgeRendering: true, edgeContrast: 1.2),
);
final leftHand = LuminaMetaHandTrackingComponent(hand: LuminaXRHand.left);
final rightHand = LuminaMetaHandTrackingComponent(hand: LuminaXRHand.right);

void setUpXr() {
  origin
    ..addComponent(passthrough)
    ..addComponent(leftHand)
    ..addComponent(rightHand);
  leftHand.attachToComponent(origin.rootComponent);
  rightHand.attachToComponent(origin.rootComponent);
}
```

## Usage

### Grabbing with a pinch

```dart
void onHandUpdate(LuminaMetaHandTrackingComponent hand, Vector3 indexTip, Vector3 thumbTip) {
  final pose = hand.currentPose
    ..isTracked = true
    ..jointLocations[MetaHandJoint.indexTip] = indexTip
    ..jointLocations[MetaHandJoint.thumbTip] = thumbTip;
  pose.computePinchFromDistances();

  if (hand.isIndexPinching) {
    // grab the object nearest to pose.jointLocations[MetaHandJoint.indexTip]
  } else if (pose.pinch.isMiddlePinching) {
    // a second gesture, e.g. pin the held object to a spatial anchor
  }
}
```

### Pinning an actor to a spatial anchor

```dart
final anchor = MetaSpatialAnchor(uuid: 'b4c1…')
  ..updatePose(Vector3(120, 40, 95), Quaternion.identity()); // localized
final pin = LuminaMetaSpatialAnchorComponent()..bindAnchor(anchor);
someActor.addComponent(pin);
```

### Reacting to the room

```dart
final table = MetaScenePlane(
  id: 'plane-1',
  label: MetaSemanticLabel.table,
  center: Vector3(80, 0, 74),
  size: Vector2(120, 60),
  normal: Vector3(0, 0, 1),
);
final surface = LuminaMetaScenePlaneComponent(plane: table);
print('${surface.label.displayName}: ${table.areaSquareMeters} m²');
```

### Face, display and foveation

```dart
final face = LuminaMetaFaceTrackingComponent();
face.expressions.setWeight(MetaFaceBlendshapes.mouthSmileL, 0.8);
face.expressions.setWeight(MetaFaceBlendshapes.mouthSmileR, 0.6);
print(face.smileIntensity); // 0.7

final perf = MetaPerformanceController(deviceModel: MetaQuestDeviceModel.quest3);
perf.requestRefreshRate(120); // true on Quest 3
perf.setFoveationLevel(MetaFoveationLevel.high, dynamic: true);
```

## Editor integration

| Where | Item | What it does |
|---|---|---|
| **Plugins → MetaXR → MetaXR Settings** | panel | Target device (Quest 2 / Pro / 3 / 3S) with its colour passthrough and face/eye tracking support, refresh rate (only the rates the device supports), foveation level and dynamic foveation. |
| **Plugins → MetaXR → Simulation Panel** | panel | Simulated hand gestures on the left or right hand — index, middle, ring and little pinch with **Tap Pinch** / **Release** and a live percentage with PINCHED / Open — and passthrough edge highlighting with its contrast. |
| **Plugins → MetaXR → Calibrate Anchors** | command | Logs a recalibration request for anchors and room planes to the Output Log (source `MetaXR`). |
| **Plugins → MetaXR → About MetaXR Support** | panel | Version and summary. |
| MCP | `lumina_plugin_metaxr.get_capabilities` (read-only) | `device_model`, `color_passthrough`, `face_tracking`, `eye_tracking`, `scene_mesh`, `refresh_rate_hz`, `foveation_level`. |
| MCP | `lumina_plugin_metaxr.simulate_pinch` (editor state) | Inputs `hand` (`left`/`right`), `finger` (`index`/`middle`/`ring`/`little`), `strength` (0..1); sets that pinch on the plugin's simulated hand (the other fingers keep theirs), updates the Simulation panel and returns `is_pinching`. |

The three panels are declarative (`PluginViewSpec`): the plugin process describes them and the editor draws them with
its own widgets. The panels, the MCP tools and the plugin's channel all read and change one simulation state. The
OpenXR base plugin adds its own menu (**Plugins → OpenXR**) and status bar button.

## Runs in its own process

The plugin is isolated (`"isolation": "process"` in `lumina_plugin_metaxr.lmplugin`, `"process_class":
"MetaXrProcess"`): Lumina Studio starts its own executable again as the plugin's process and talks to it over a
local connection.

- **In the plugin process (`MetaXrProcess`)**: the four menu commands, both MCP tools, the anchor calibration (it
  writes through the proxied level access), the Settings / Simulation / About panels and the simulation state they
  share (device, refresh rate, foveation, both hands' pinches, passthrough style). It also answers the channel
  method `getState` and emits `stateChanged` with the same JSON after every change.
- **In the editor**: nothing of the plugin's code. The plugin builds no widgets, so it has no in-process part: its
  editor module names only a `process_class` (no `registration_class`), and the editor draws its panels from the
  specs the process sends.
- The process part imports only `package:lumina_plugin_openxr/xr_types.dart` (the hand identifiers, no `dart:ffi`)
  from the OpenXR base plugin.
- **When the process stops** (crash, hang, or killed): the editor keeps running, greys the plugin's menu items,
  shows the stop on its panels with **Restart**, lists the state, exit code and log tail in the Plugin Manager and
  files a plugin crash report. A restarted process starts from the default simulation state (Quest 3, 90 Hz, open
  hands).
- **Debugging in the editor's process**: set the project override in the `.lmproject`
  `"plugin_isolation": {"lumina_plugin_metaxr": "in_process"}`; the same process part then runs inside the editor
  over an in-memory connection, so breakpoints work without attaching to a second process.

## Working without a headset

Every type is plain Dart state, so a whole MR interaction can be built and tested on a desktop: drive hand poses and
pinches from the mouse, from tests or through `simulate_pinch` from an MCP client; create anchors and scene planes
with the poses you want; switch the target device in the settings to see which features and refresh rates it
offers. The base plugin's simulated headset supplies the head and controller poses.

## Architecture

```
lib/
  lumina_plugin_metaxr.dart            public library
  src/metaxr_info.dart                 MetaXrInfo: name, display name, version
  src/process/       MetaXrProcess (menus, MCP tools, panels), MetaXrState, MetaXrViews (panel specs)
  src/meta_extensions.dart             MetaOpenXrExtensions
  src/meta_device.dart                 MetaQuestDeviceModel
  src/passthrough/   MetaPassthroughLayer, MetaPassthroughStyle, LuminaMetaPassthroughComponent
  src/hand/          MetaHandJoint, MetaHandPose, MetaPinchState, MetaHandMeshGenerator, LuminaMetaHandTrackingComponent
  src/spatial/       MetaSpatialAnchor, MetaScenePlane, LuminaMetaSpatialAnchorComponent, LuminaMetaScenePlaneComponent
  src/social/        MetaFaceBlendshapes, MetaFaceExpressionWeights, MetaEyeTrackingData, LuminaMetaFaceTrackingComponent
  src/performance/   MetaPerformanceController, MetaFoveationLevel
```

- **Layering.** The plugin is pure Dart on top of `lumina_plugin_openxr`. When the base plugin's bridge creates the
  OpenXR instance and session, the Meta extensions will be enabled there and their results written into these same
  types; components and game code will not change.
- **Threading and frame loop.** All state is synchronous and owned by the isolate running the world. The game updates
  hand poses, anchors and planes in its tick and reads pinch and gaze results in the same frame.
- **Rendering.** Passthrough is a compositor layer: with `underlay` the virtual scene is drawn over the camera image
  where its alpha allows, with `overlay` the camera image is drawn over the scene. The debug hand geometry is plain
  triangle data for any Lumina/Filament mesh.

## Coordinate systems and units

Lumina world units are centimetres with Z up in stored transforms. Hand joint locations and the pinch thresholds
(1.5 cm / 8 cm), anchor poses and scene plane centres and sizes are in Lumina centimetres; `areaSquareMeters`
converts the plane's area. Convert raw OpenXR poses (metres, Y-up) with the base plugin's `OpenXrSpaceConverter`
before writing them into these types. Eye gaze directions are unit vectors; pupil diameters are millimetres.

## Testing

```bash
flutter test test/meta_extensions_and_device_test.dart
flutter test test/meta_hand_tracking_test.dart
flutter test test/meta_passthrough_test.dart
flutter test test/meta_social_and_performance_test.dart
flutter test test/meta_spatial_test.dart
flutter test test/metaxr_process_test.dart
flutter test test/metaxr_editor_integration_test.dart
flutter analyze
```

The tests cover the extension names, the device capability flags, the 26 joints, pinch detection (per finger and
from joint distances), the debug geometry, the passthrough style and layer lifecycle, the face metrics, refresh rate
and foveation negotiation, anchors and scene planes, and the plugin process: `metaxr_process_test.dart` runs `MetaXrProcess` under
`runPluginProcessMain` against a real loopback editor (`LoopbackHost`) and checks the contributions, every menu
command, both MCP tools, the panel events and updates, and that bad input answers an error while the process keeps
serving; `metaxr_editor_integration_test.dart` checks the manifest (process isolation, no registration class) and that
the plugin channel reaches the process. No headset or GPU is needed.

## Troubleshooting

- **The plugin does not appear or fails to enable.** Install and enable OpenXR Support first; the manifest requires
  `lumina_plugin_openxr` 0.1.0 or later.
- **A refresh rate is refused.** `requestRefreshRate` accepts only the rates of the selected device profile (Quest
  Pro has no 80 or 120 Hz).
- **Face or eye values stay at zero.** They are written by your code or a simulation today; on hardware they will
  need Quest Pro with face/eye tracking allowed.
- **Pinch never triggers.** Strength must reach `pinchThreshold` (0.70); with `computePinchFromDistances` the thumb
  and finger tips must be within about 3.5 cm, in centimetres.

## Limitations and roadmap

- No `XR_FB_*` calls yet; all data is set by the application, the simulation panel or MCP (see [Status](#status)).
- The 63 face weights have named indices for the brows, eyes, cheeks, jaw, mouth and lips; their order is the
  plugin's own and will be mapped to the runtime's expression order (`XR_FB_face_tracking2` reports 70 expressions)
  when native face data arrives.
- `XR_FB_body_tracking`, `XR_FB_hand_tracking_capsules` and `XR_FB_triangle_mesh` are catalogued but have no
  component yet.
- **Calibrate Anchors** only logs the request; the simulation panel drives the right hand only.
- `MetaHandPose.aimDirection` defaults to +X, following the base plugin's forward axis.

Planned next, as the base plugin gains instance and session creation: enabling the extensions the device reports,
passthrough layers submitted with the frame, hand joints and aim from `xrLocateHandJointsEXT`, anchors created,
saved and shared through the spatial entity extensions, scene planes from Space Setup, face and eye data on Quest
Pro, and refresh rate and foveation applied on the device.

## Contributing

Issues and pull requests are welcome. Keep `flutter analyze` clean, add unit tests for new behaviour, keep both
READMEs (English and Turkish) in step, and use `shadcn_flutter` widgets for UI.

## License

MIT — see [LICENSE](LICENSE).

This repository contains no third-party source or binaries; it does not vendor the Meta OpenXR SDK or the Khronos
OpenXR SDK. Extension names are used as identifiers only. Meta Quest is a trademark of Meta Platforms, Inc.;
OpenXR™ is a trademark of The Khronos Group Inc.
