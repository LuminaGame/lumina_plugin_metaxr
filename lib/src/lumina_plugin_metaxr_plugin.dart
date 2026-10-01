import 'package:lumina_editor_api/lumina_editor_api.dart';
import 'package:lumina_plugin_openxr/lumina_plugin_openxr.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'hand/meta_hand_pose.dart';
import 'passthrough/meta_passthrough_style.dart';
import 'performance/meta_performance_controller.dart';
import 'ui/metaxr_settings_view.dart';
import 'ui/metaxr_simulation_panel.dart';

/// Meta Quest OpenXR SDK plugin for Lumina Studio.
class LuminaPluginMetaxrPlugin extends LuminaEditorPlugin {
  static const String friendlyName = 'MetaXR Support';
  static const String version = '0.1.0';

  final MetaPerformanceController performance = MetaPerformanceController();
  final MetaHandPose leftHand = MetaHandPose(hand: LuminaXRHand.left);
  final MetaHandPose rightHand = MetaHandPose(hand: LuminaXRHand.right);

  MetaPassthroughStyle currentPassthroughStyle = const MetaPassthroughStyle();
  EditorLevelAccess? _level;

  @override
  String get pluginName => 'lumina_plugin_metaxr';

  @override
  void register(LuminaEditorContext context) {
    if (context is LuminaEditorHostContext) {
      _level = context.level;
    }

    // 1. Menu: MetaXR Settings
    context.registerMenuItem(
      'Plugins/MetaXR/MetaXR Settings',
      EditorCommand(
        id: 'tools.lumina_plugin_metaxr.settings',
        label: 'MetaXR Settings',
        icon: LucideIcons.settings,
        canExecute: () => true,
        execute: (ctx) {
          if (ctx == null) return;
          showOverlay<void>(
            ctx,
            const DialogConfiguration(),
            builder: (c) => AlertDialog(
              title: const Text('MetaXR Settings'),
              content: SizedBox(
                width: 520,
                child: MetaXrSettingsView(performance: performance),
              ),
              actions: [
                PrimaryButton(onPressed: () => closeOverlay<void>(c), child: const Text('Close')),
              ],
            ),
          );
        },
      ),
      options: const EditorMenuItemOptions(section: 'settings'),
    );

    // 2. Menu: Simulation Panel
    context.registerMenuItem(
      'Plugins/MetaXR/Simulation Panel',
      EditorCommand(
        id: 'tools.lumina_plugin_metaxr.simulationPanel',
        label: 'OpenXR / MetaXR Simulation Panel',
        icon: LucideIcons.cpu,
        canExecute: () => true,
        execute: (ctx) {
          if (ctx == null) return;
          showOverlay<void>(
            ctx,
            const DialogConfiguration(),
            builder: (c) => AlertDialog(
              title: const Text('MetaXR Simulation'),
              content: SizedBox(
                width: 500,
                child: MetaXrSimulationPanel(
                  leftHand: leftHand,
                  rightHand: rightHand,
                  onStyleChanged: (s) => currentPassthroughStyle = s,
                ),
              ),
              actions: [
                PrimaryButton(onPressed: () => closeOverlay<void>(c), child: const Text('Done')),
              ],
            ),
          );
        },
      ),
      options: const EditorMenuItemOptions(section: 'tools'),
    );

    // 3. Menu: Calibrate Anchors
    context.registerMenuItem(
      'Plugins/MetaXR/Calibrate Anchors',
      EditorCommand(
        id: 'tools.lumina_plugin_metaxr.calibrateAnchors',
        label: 'Calibrate Spatial Anchors',
        icon: LucideIcons.mapPin,
        canExecute: () => true,
        execute: (ctx) {
          _level?.log('Recalibrating Meta Quest spatial anchors and room planes', level: 'info', source: 'MetaXR');
        },
      ),
      options: const EditorMenuItemOptions(section: 'run'),
    );

    // 4. Menu: About
    context.registerMenuItem(
      'Plugins/MetaXR/About $friendlyName',
      EditorCommand(
        id: 'tools.lumina_plugin_metaxr.about',
        label: 'About $friendlyName',
        canExecute: () => true,
        execute: (ctx) {
          if (ctx == null) return;
          showOverlay<void>(
            ctx,
            const DialogConfiguration(),
            builder: (c) => AlertDialog(
              title: const Text(friendlyName),
              content: const Text(
                'Meta Quest OpenXR SDK plugin: Passthrough mixed reality, 26-joint hand tracking with pinch detection, '
                'spatial anchors, room scene perception, and social expression tracking.\nVersion: $version',
              ),
              actions: [
                PrimaryButton(onPressed: () => closeOverlay<void>(c), child: const Text('Close')),
              ],
            ),
          );
        },
      ),
      options: const EditorMenuItemOptions(section: 'about'),
    );

    // 5. Register MCP Tools for AI agents
    context.mcp.registerTool(
      McpTool(
        name: 'get_capabilities',
        description: 'Returns active Meta Quest device model and supported hardware capabilities.',
        inputSchema: const {'type': 'object', 'properties': <String, Object?>{}},
        risk: McpToolRisk.readOnly,
        groups: const {McpToolGroups.plugin},
        handler: (args) async => McpToolResult.json({
          'device_model': performance.deviceModel.displayName,
          'color_passthrough': performance.deviceModel.hasColorPassthrough,
          'face_tracking': performance.deviceModel.hasFaceTracking,
          'eye_tracking': performance.deviceModel.hasEyeTracking,
          'scene_mesh': performance.deviceModel.hasSceneMesh,
          'refresh_rate_hz': performance.currentRefreshRate,
          'foveation_level': performance.foveationLevel.name,
        }),
      ),
    );

    context.mcp.registerTool(
      McpTool(
        name: 'simulate_pinch',
        description: 'Injects a simulated hand pinch gesture on the specified hand.',
        inputSchema: const {
          'type': 'object',
          'properties': <String, Object?>{
            'hand': {'type': 'string', 'enum': ['left', 'right']},
            'finger': {'type': 'string', 'enum': ['index', 'middle', 'ring', 'little']},
            'strength': {'type': 'number', 'minimum': 0.0, 'maximum': 1.0},
          },
          'required': ['hand', 'finger', 'strength'],
        },
        risk: McpToolRisk.editorState,
        groups: const {McpToolGroups.plugin},
        handler: (args) async {
          final isLeft = args.string('hand') == 'left';
          final finger = args.string('finger');
          final strength = args.number('strength');

          final targetPose = isLeft ? leftHand : rightHand;
          if (finger == 'index') targetPose.pinch.update(index: strength);
          if (finger == 'middle') targetPose.pinch.update(middle: strength);
          if (finger == 'ring') targetPose.pinch.update(ring: strength);
          if (finger == 'little') targetPose.pinch.update(little: strength);

          return McpToolResult.json({
            'status': 'success',
            'hand': isLeft ? 'left' : 'right',
            'finger': finger,
            'strength': strength,
            'is_pinching': targetPose.pinch.isAnyPinching,
          });
        },
      ),
    );
  }

  @override
  void unregister(LuminaEditorContext context) {
    _level = null;
  }
}
