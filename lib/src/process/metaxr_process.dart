import 'package:lumina_editor_api/lumina_editor_api.dart';
import 'package:lumina_plugin_openxr/xr_types.dart' show LuminaXRHand;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;

import 'package:lumina_plugin_metaxr/src/meta_device.dart';
import 'package:lumina_plugin_metaxr/src/performance/meta_performance_controller.dart';
import 'package:lumina_plugin_metaxr/src/process/metaxr_state.dart';
import 'package:lumina_plugin_metaxr/src/process/metaxr_views.dart';

/// MetaXR Support as it runs in its own plugin process: the menu commands,
/// the MCP tools, the anchor calibration (through the level proxy) and three
/// declarative panels (Settings, Simulation, About) the editor renders. The
/// simulation state ([state]) lives here only; the panels, the MCP tools and
/// the channel all change the same copy, and every change re-sends the
/// panels and emits `stateChanged`.
///
/// Channel surface (`context.processChannel('lumina_plugin_metaxr')`):
/// - `getState` → [MetaXrState.toJson].
/// - event `stateChanged` with the same JSON after every change.
class MetaXrProcess extends LuminaPluginProcess {
  MetaXrProcess();

  /// The simulation state shared by the panels, the MCP tools and the channel.
  final MetaXrState state = MetaXrState();

  late PluginProcessContext _context;

  @override
  String get pluginName => MetaXrViews.pluginName;

  @override
  void register(PluginProcessContext context) {
    _context = context;

    context.registerMenuItem(
      'Plugins/MetaXR/MetaXR Settings',
      PluginProcessCommand(
        id: 'tools.$pluginName.settings',
        label: 'MetaXR Settings',
        icon: pluginIconOf(LucideIcons.settings),
        run: () => context.showPanel(MetaXrViews.settingsPanelId),
      ),
      section: 'settings',
    );
    context.registerMenuItem(
      'Plugins/MetaXR/Simulation Panel',
      PluginProcessCommand(
        id: 'tools.$pluginName.simulationPanel',
        label: 'OpenXR / MetaXR Simulation Panel',
        icon: pluginIconOf(LucideIcons.cpu),
        run: () => context.showPanel(MetaXrViews.simulationPanelId),
      ),
      section: 'tools',
    );
    context.registerMenuItem(
      'Plugins/MetaXR/Calibrate Anchors',
      PluginProcessCommand(
        id: 'tools.$pluginName.calibrateAnchors',
        label: 'Calibrate Spatial Anchors',
        icon: pluginIconOf(LucideIcons.mapPin),
        run: calibrateAnchors,
      ),
      section: 'run',
    );
    context.registerMenuItem(
      'Plugins/MetaXR/About ${MetaXrViews.friendlyName}',
      PluginProcessCommand(
        id: 'tools.$pluginName.about',
        label: 'About ${MetaXrViews.friendlyName}',
        icon: pluginIconOf(LucideIcons.info),
        run: () => context.showPanel(MetaXrViews.aboutPanelId),
      ),
      section: 'about',
    );

    context.registerViewPanel(PluginProcessViewPanel(
      id: MetaXrViews.settingsPanelId,
      title: 'MetaXR Settings',
      icon: pluginIconOf(LucideIcons.settings),
      dock: 'right',
      initial: MetaXrViews.settings(state),
      onEvent: (event, _) => _onSettingsEvent(event),
    ));
    context.registerViewPanel(PluginProcessViewPanel(
      id: MetaXrViews.simulationPanelId,
      title: 'MetaXR Simulation',
      icon: pluginIconOf(LucideIcons.cpu),
      dock: 'right',
      initial: MetaXrViews.simulation(state),
      onEvent: (event, _) => _onSimulationEvent(event),
    ));
    context.registerViewPanel(PluginProcessViewPanel(
      id: MetaXrViews.aboutPanelId,
      title: 'About ${MetaXrViews.friendlyName}',
      icon: pluginIconOf(LucideIcons.info),
      dock: 'floating',
      initial: MetaXrViews.about,
      onEvent: (_, _) {},
    ));

    context.registerMcpTool(McpTool(
      name: 'get_capabilities',
      description: 'Returns active Meta Quest device model and supported hardware capabilities.',
      inputSchema: const {'type': 'object', 'properties': <String, Object?>{}},
      risk: McpToolRisk.readOnly,
      groups: const {McpToolGroups.plugin},
      handler: (args) async => McpToolResult.json(state.capabilitiesJson()),
    ));
    context.registerMcpTool(McpTool(
      name: 'simulate_pinch',
      description: 'Injects a simulated hand pinch gesture on the specified hand.',
      inputSchema: const {
        'type': 'object',
        'properties': <String, Object?>{
          'hand': {'type': 'string', 'enum': ['left', 'right']},
          'finger': {'type': 'string', 'enum': kMetaPinchFingers},
          'strength': {'type': 'number', 'minimum': 0.0, 'maximum': 1.0},
        },
        'required': ['hand', 'finger', 'strength'],
      },
      risk: McpToolRisk.editorState,
      groups: const {McpToolGroups.plugin},
      handler: (args) async {
        final hand = args.string('hand') == 'left' ? LuminaXRHand.left : LuminaXRHand.right;
        final finger = args.string('finger');
        final strength = args.number('strength');
        if (!kMetaPinchFingers.contains(finger)) {
          return McpToolResult.error('finger must be one of ${kMetaPinchFingers.join(', ')}, got "$finger"');
        }
        state.setPinch(hand, finger, strength);
        _changed();
        return McpToolResult.json({
          'status': 'success',
          'hand': hand.name,
          'finger': finger,
          'strength': state.pinchOf(hand, finger),
          'is_pinching': state.hand(hand).pinch.isAnyPinching,
        });
      },
    ));

    context.handle('getState', (_) => state.toJson());
  }

  /// Writes the anchor and room-plane recalibration request to the editor's
  /// log (the level's output log, under "MetaXR").
  void calibrateAnchors() {
    _context.level.log('Recalibrating Meta Quest spatial anchors and room planes', level: 'info', source: 'MetaXR');
  }

  void _onSettingsEvent(PluginViewEvent event) {
    if (event.kind != 'changed') return;
    final v = event.value;
    switch (event.controlId) {
      case 'device':
        state.selectDevice(MetaQuestDeviceModel.values.byName('$v'));
      case 'refreshRate':
        final hz = double.tryParse('$v');
        if (hz == null || !state.performance.requestRefreshRate(hz)) {
          _context.log('MetaXR: ${state.performance.deviceModel.displayName} has no $v Hz mode', level: 'warning');
        }
      case 'foveation':
        state.performance.setFoveationLevel(MetaFoveationLevel.values.byName('$v'),
            dynamic: state.performance.useDynamicFoveation);
      case 'dynamicFoveation':
        state.performance.setFoveationLevel(state.performance.foveationLevel, dynamic: v == true);
      default:
        return;
    }
    _changed();
  }

  void _onSimulationEvent(PluginViewEvent event) {
    final id = event.controlId;
    final v = event.value;
    if (event.kind == 'pressed' && (id.startsWith('tap.') || id.startsWith('release.'))) {
      final finger = id.substring(id.indexOf('.') + 1);
      state.setPinch(state.simulatedHand, finger, id.startsWith('tap.') ? 1.0 : 0.0);
    } else if (event.kind == 'changed' && id == 'hand') {
      state.simulatedHand = LuminaXRHand.values.byName('$v');
    } else if (event.kind == 'changed' && id == 'edges') {
      state.passthroughStyle = state.passthroughStyle.copyWith(enableEdgeRendering: v == true);
    } else if (event.kind == 'changed' && id == 'edgeContrast' && v is num) {
      state.passthroughStyle = state.passthroughStyle.copyWith(edgeContrast: v.toDouble().clamp(0.0, 1.0));
    } else {
      return;
    }
    _changed();
  }

  /// Re-sends both stateful panels and emits `stateChanged` on the channel.
  void _changed() {
    _context.view(MetaXrViews.settingsViewId)?.replace(MetaXrViews.settings(state));
    _context.view(MetaXrViews.simulationViewId)?.replace(MetaXrViews.simulation(state));
    _context.emit('stateChanged', state.toJson());
  }
}

