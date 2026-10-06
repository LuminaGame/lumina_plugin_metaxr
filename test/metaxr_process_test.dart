import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_editor_api/lumina_editor_api.dart';
import 'package:lumina_editor_api/testing.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';
import 'package:lumina_plugin_openxr/xr_types.dart' show LuminaXRHand;

void main() {
  late LoopbackHost host;
  late MetaXrProcess process;
  late Future<int> exit;
  late PluginContributions contributions;

  setUp(() async {
    host = await LoopbackHost.start();
    process = MetaXrProcess();
    exit = runPluginProcessMain(host.launch(MetaXrViews.pluginName), process);
    contributions = await host.contributions;
  });

  tearDown(() async {
    await host.call(PluginMethods.shutdown);
    expect(await exit, PluginProcessExitCodes.ok);
    await host.close();
  });

  Future<McpToolResult> tool(String name, Map<String, Object?> args) async {
    final r = await host.call(PluginMethods.mcpTool, {'tool': '${MetaXrViews.pluginName}.$name', 'arguments': args});
    return McpToolResult.fromJson((r as Map).cast());
  }

  Future<void> viewEvent(String viewId, String controlId, String kind, [Object? value]) =>
      host.call(PluginMethods.viewEvent,
          PluginViewEvent(viewId: viewId, controlId: controlId, kind: kind, value: value).toJson());

  /// The next full spec the process sent for [viewId].
  Future<PluginViewSpec> nextView(String viewId) async {
    final n = await host.next(PluginMethods.view, where: (a) => a['viewId'] == viewId && a['spec'] is Map);
    return PluginViewSpec.fromJson((n['spec'] as Map).cast());
  }

  String textOf(PluginViewSpec spec, String controlId) => spec.find(controlId)!['value'] as String;

  test('registers the menu commands, three declarative panels and both MCP tools, no widgets', () {
    final items = {for (final i in contributions.menuItems) i.path: i};
    expect(items.keys, [
      'Plugins/MetaXR/MetaXR Settings',
      'Plugins/MetaXR/Simulation Panel',
      'Plugins/MetaXR/Calibrate Anchors',
      'Plugins/MetaXR/About MetaXR Support',
    ]);
    expect(items['Plugins/MetaXR/MetaXR Settings']!.section, 'settings');
    expect(items['Plugins/MetaXR/Calibrate Anchors']!.command.id, 'tools.lumina_plugin_metaxr.calibrateAnchors');
    expect(items.values.every((i) => i.command.icon != null), isTrue);

    expect([for (final p in contributions.panels) p.id], [
      MetaXrViews.settingsPanelId,
      MetaXrViews.simulationPanelId,
      MetaXrViews.aboutPanelId,
    ]);
    final settings = contributions.panels.first.view;
    expect(settings.find('device')!['value'], 'quest3');
    expect(settings.find('refreshRate')!['value'], '90');
    expect(textOf(contributions.panels[2].view, 'version'), 'Version ${MetaXrViews.version}');

    expect([for (final t in contributions.mcpTools) t.name], ['get_capabilities', 'simulate_pinch']);
    expect(contributions.mcpTools.last.risk, McpToolRisk.editorState.name);
    expect(contributions.importers, isEmpty);
  });

  test('menu commands open the panels in the editor and calibrate through the level proxy', () async {
    for (final id in ['settings', 'simulationPanel', 'about']) {
      await host.call(PluginMethods.command, {'commandId': 'tools.lumina_plugin_metaxr.$id'});
    }
    final shown = [
      for (final (m, a) in host.requests)
        if (m == PluginMethods.panels && a['op'] == 'show') a['panelId'],
    ];
    expect(shown, [MetaXrViews.settingsPanelId, MetaXrViews.simulationPanelId, MetaXrViews.aboutPanelId]);

    await host.call(PluginMethods.command, {'commandId': 'tools.lumina_plugin_metaxr.calibrateAnchors'});
    final log = await host.next(PluginMethods.log, where: (a) => '${a['message']}'.contains('spatial anchors'));
    expect(log['source'], 'MetaXR');
    expect(log['level'], 'info');
  });

  test('get_capabilities answers the device the settings panel selected', () async {
    final before = await tool('get_capabilities', {});
    expect(before.isError, isFalse);
    expect(before.structuredContent, {
      'device_model': 'Meta Quest 3',
      'color_passthrough': true,
      'face_tracking': false,
      'eye_tracking': false,
      'scene_mesh': true,
      'refresh_rate_hz': 90.0,
      'foveation_level': 'medium',
    });

    await viewEvent(MetaXrViews.settingsViewId, 'device', 'changed', 'questPro');
    final spec = await nextView(MetaXrViews.settingsViewId);
    expect(textOf(spec, 'faceTracking'), 'Face tracking: Supported');
    expect([for (final o in spec.find('refreshRate')!['options'] as List) (o as Map)['value']], ['72', '90']);

    await viewEvent(MetaXrViews.settingsViewId, 'refreshRate', 'changed', '72');
    await viewEvent(MetaXrViews.settingsViewId, 'foveation', 'changed', 'high');
    await viewEvent(MetaXrViews.settingsViewId, 'dynamicFoveation', 'changed', false);
    final after = (await tool('get_capabilities', {})).structuredContent!;
    expect(after['device_model'], 'Meta Quest Pro');
    expect(after['eye_tracking'], isTrue);
    expect(after['refresh_rate_hz'], 72.0);
    expect(after['foveation_level'], 'high');
    expect(process.state.performance.useDynamicFoveation, isFalse);

    // A rate the device lacks is refused with a warning; the state stays.
    await viewEvent(MetaXrViews.settingsViewId, 'refreshRate', 'changed', '120');
    final warning = await host.next(PluginMethods.log, where: (a) => a['level'] == 'warning');
    expect(warning['message'], contains('no 120 Hz mode'));
    expect(process.state.performance.currentRefreshRate, 72.0);
  });

  test('simulate_pinch drives the simulated hand, updates the panel and emits stateChanged', () async {
    final state = host.next(PluginMethods.event, where: (a) => a['name'] == 'stateChanged');
    final r = await tool('simulate_pinch', {'hand': 'right', 'finger': 'index', 'strength': 0.9});
    expect(r.structuredContent, {
      'status': 'success',
      'hand': 'right',
      'finger': 'index',
      'strength': 0.9,
      'is_pinching': true,
    });
    expect(process.state.rightHand.pinch.isIndexPinching, isTrue);
    expect(textOf(await nextView(MetaXrViews.simulationViewId), 'status.index'), 'Index pinch: 90% · PINCHED');
    final data = ((await state)['data'] as Map).cast<String, Object?>();
    expect((data['hands'] as Map)['right'], containsPair('index', 0.9));

    // Another finger keeps the first one.
    await tool('simulate_pinch', {'hand': 'right', 'finger': 'little', 'strength': 0.3});
    expect(process.state.rightHand.pinch.indexStrength, 0.9);
    expect(process.state.rightHand.pinch.littleStrength, 0.3);
    expect(process.state.leftHand.pinch.isAnyPinching, isFalse);
  });

  test('the simulation panel taps and releases pinches on the chosen hand and styles passthrough', () async {
    await viewEvent(MetaXrViews.simulationViewId, 'hand', 'changed', 'left');
    expect(process.state.simulatedHand, LuminaXRHand.left);
    await viewEvent(MetaXrViews.simulationViewId, 'tap.middle', 'pressed');
    expect(process.state.leftHand.pinch.isMiddlePinching, isTrue);
    expect(process.state.rightHand.pinch.isAnyPinching, isFalse);
    await nextView(MetaXrViews.simulationViewId); // after the hand change
    final spec = await nextView(MetaXrViews.simulationViewId); // after the tap
    expect(spec.find('hand')!['value'], 'left');
    expect(textOf(spec, 'status.middle'), 'Middle pinch: 100% · PINCHED');

    await viewEvent(MetaXrViews.simulationViewId, 'release.middle', 'pressed');
    expect(process.state.leftHand.pinch.middleStrength, 0.0);

    await viewEvent(MetaXrViews.simulationViewId, 'edges', 'changed', true);
    await viewEvent(MetaXrViews.simulationViewId, 'edgeContrast', 'changed', 0.4);
    expect(process.state.passthroughStyle.enableEdgeRendering, isTrue);
    expect(process.state.passthroughStyle.edgeContrast, 0.4);

    final got = await host.channel.call('getState') as Map;
    expect(got['simulated_hand'], 'left');
    expect(got['passthrough'], {'edge_rendering': true, 'edge_contrast': 0.4});
  });

  test('bad input answers an error and the process keeps serving', () async {
    final unknownFinger = await tool('simulate_pinch', {'hand': 'left', 'finger': 'thumb', 'strength': 1});
    expect(unknownFinger.isError, isTrue);

    await expectLater(
      tool('simulate_pinch', {'finger': 'index', 'strength': 1}),
      throwsA(isA<PluginRemoteError>().having((e) => e.code, 'code', PluginErrorCodes.badArguments)),
    );
    await expectLater(
      viewEvent(MetaXrViews.settingsViewId, 'device', 'changed', 'quest9'),
      throwsA(isA<PluginRemoteError>()),
    );
    final logged = await host.next(PluginMethods.log, where: (a) => a['level'] == 'error');
    expect(logged['message'], contains('quest9'));

    expect(await host.call(PluginMethods.ping), isA<Map<String, Object?>>());
    expect(process.state.performance.deviceModel, MetaQuestDeviceModel.quest3);
    expect((await tool('get_capabilities', {})).isError, isFalse);
  });
}
