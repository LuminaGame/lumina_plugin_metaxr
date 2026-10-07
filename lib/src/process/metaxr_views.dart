import 'package:lumina_plugin_openxr/xr_types.dart' show LuminaXRHand;
import 'package:lumina_plugin_process/lumina_plugin_process.dart';

import 'package:lumina_plugin_metaxr/src/hand/meta_pinch_state.dart';
import 'package:lumina_plugin_metaxr/src/meta_device.dart';
import 'package:lumina_plugin_metaxr/src/metaxr_info.dart';
import 'package:lumina_plugin_metaxr/src/performance/meta_performance_controller.dart';
import 'package:lumina_plugin_metaxr/src/process/metaxr_state.dart';

/// The declarative panels of MetaXR Support. The plugin process builds them
/// from [MetaXrState]; the editor renders them with its own widgets and sends
/// the user's actions back as `PluginViewEvent`s.
abstract final class MetaXrViews {
  static const String pluginName = MetaXrInfo.pluginName;
  static const String friendlyName = MetaXrInfo.friendlyName;
  static const String version = MetaXrInfo.version;

  static const String settingsPanelId = 'panel.$pluginName.settings';
  static const String simulationPanelId = 'panel.$pluginName.simulation';
  static const String aboutPanelId = 'panel.$pluginName.about';

  static const String settingsViewId = '$pluginName.settings';
  static const String simulationViewId = '$pluginName.simulation';
  static const String aboutViewId = '$pluginName.about';

  /// Lucide icons as protocol data (the editor maps them back to its
  /// bundled constants).
  static const PluginIconSpec settingsIcon = PluginIconSpec(57687, fontFamily: _lucide, fontPackage: _shadcn);
  static const PluginIconSpec cpuIcon = PluginIconSpec(57517, fontFamily: _lucide, fontPackage: _shadcn);
  static const PluginIconSpec mapPinIcon = PluginIconSpec(57620, fontFamily: _lucide, fontPackage: _shadcn);
  static const PluginIconSpec infoIcon = PluginIconSpec(57598, fontFamily: _lucide, fontPackage: _shadcn);
  static const String _lucide = 'LucideIcons';
  static const String _shadcn = 'shadcn_flutter';

  static String _supported(bool v, String no) => v ? 'Supported' : no;

  static String _rate(double hz) => '${hz.toInt()}';

  /// Target device, its capabilities, refresh rate and foveation.
  static PluginViewSpec settings(MetaXrState state) {
    final perf = state.performance;
    final d = perf.deviceModel;
    return PluginViewSpec(id: settingsViewId, children: [
      PluginControl.text('intro', 'Configure Meta OpenXR SDK capabilities, passthrough and device profiles.',
          style: 'muted'),
      PluginControl.section('deviceSection', 'Target Quest Device', [
        PluginControl.enumField('device', label: 'Device', value: d.name, options: [
          for (final m in MetaQuestDeviceModel.values) (m.name, m.displayName),
        ]),
        PluginControl.text('colorPassthrough', 'Color passthrough: ${_supported(d.hasColorPassthrough, 'Monochrome IR')}'),
        PluginControl.text('faceTracking', 'Face tracking: ${_supported(d.hasFaceTracking, 'Unsupported')}'),
        PluginControl.text('eyeTracking', 'Eye tracking: ${_supported(d.hasEyeTracking, 'Unsupported')}'),
        PluginControl.text('sceneMesh', 'Scene mesh: ${_supported(d.hasSceneMesh, 'Unsupported')}'),
      ]),
      PluginControl.section('displaySection', 'Display & GPU Performance', [
        PluginControl.enumField('refreshRate', label: 'Refresh rate', value: _rate(perf.currentRefreshRate), options: [
          for (final hz in d.supportedRefreshRates) (_rate(hz), '${_rate(hz)} Hz'),
        ]),
        PluginControl.enumField('foveation', label: 'Foveated rendering level', value: perf.foveationLevel.name, options: [
          for (final f in MetaFoveationLevel.values) (f.name, f.name),
        ]),
        PluginControl.boolField('dynamicFoveation', label: 'Dynamic foveation', value: perf.useDynamicFoveation),
      ]),
    ]);
  }

  static String _fingerLabel(String finger) => '${finger[0].toUpperCase()}${finger.substring(1)}';

  /// The pinch status line of [finger] on the simulated hand.
  static String pinchStatus(MetaXrState state, String finger) {
    final s = state.pinchOf(state.simulatedHand, finger);
    final pinched = s >= MetaPinchState.defaultPinchThreshold;
    return '${_fingerLabel(finger)} pinch: ${(s * 100).round()}% · ${pinched ? 'PINCHED' : 'Open'}';
  }

  /// Simulated hand gestures and passthrough edge styling.
  static PluginViewSpec simulation(MetaXrState state) => PluginViewSpec(id: simulationViewId, children: [
        PluginControl.text('intro', 'Simulate hand gestures and passthrough styles in the editor, without a headset.',
            style: 'muted'),
        PluginControl.section('handsSection', 'Hand Tracking Gestures', [
          PluginControl.enumField('hand', label: 'Hand', value: state.simulatedHand.name, options: [
            for (final h in LuminaXRHand.values) (h.name, h == LuminaXRHand.left ? 'Left hand' : 'Right hand'),
          ]),
          for (final f in kMetaPinchFingers)
            PluginControl.row('row.$f', [
              PluginControl.text('status.$f', pinchStatus(state, f)),
              PluginControl.button('tap.$f', 'Tap Pinch', tone: 'primary'),
              PluginControl.button('release.$f', 'Release'),
            ]),
        ]),
        PluginControl.section('passthroughSection', 'Passthrough Edge Styling', [
          PluginControl.boolField('edges', label: 'Highlight surface edges', value: state.passthroughStyle.enableEdgeRendering),
          PluginControl.numberField('edgeContrast',
              label: 'Edge contrast', value: state.passthroughStyle.edgeContrast, min: 0, max: 1, step: 0.05),
        ]),
      ]);

  /// The plugin's name, purpose and version.
  static const PluginViewSpec about = PluginViewSpec(id: aboutViewId, children: [
    PluginControl(kind: PluginControlKind.text, id: 'name', props: {'value': friendlyName, 'style': 'heading'}),
    PluginControl(kind: PluginControlKind.text, id: 'description', props: {
      'value': 'Meta Quest OpenXR SDK plugin: passthrough mixed reality, 26-joint hand tracking with pinch '
          'detection, spatial anchors, room scene perception and social expression tracking.',
      'style': 'body',
    }),
    PluginControl(kind: PluginControlKind.text, id: 'version', props: {'value': 'Version $version', 'style': 'muted'}),
  ]);
}
