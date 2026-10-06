import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_editor_api/lumina_editor_api.dart';
import 'package:lumina_editor_api/testing.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';

void main() {
  test('the manifest runs the plugin as a process with no in-process registration class', () async {
    final manifest = jsonDecode(await File('lumina_plugin_metaxr.lmplugin').readAsString()) as Map<String, Object?>;
    expect(manifest['name'], MetaXrInfo.pluginName);
    expect(manifest['friendly_name'], MetaXrInfo.friendlyName);
    expect(manifest['version'], MetaXrInfo.version);
    expect(manifest['isolation'], 'process');
    final module = ((manifest['modules'] as List).single as Map).cast<String, Object?>();
    expect(module['type'], 'editor');
    expect(module['process_class'], 'MetaXrProcess');
    expect(module.containsKey('registration_class'), isFalse);
    expect(MetaXrProcess().pluginName, MetaXrInfo.pluginName);
  });

  group('MetaXR editor integration', () {
    late LoopbackHost host;
    late Future<int> exit;
    late MetaXrProcess process;

    setUp(() async {
      host = await LoopbackHost.start();
      process = MetaXrProcess();
      exit = runPluginProcessMain(host.launch(MetaXrInfo.pluginName), process);
      await host.contributions;
    });

    tearDown(() async {
      await host.call(PluginMethods.shutdown);
      expect(await exit, PluginProcessExitCodes.ok);
      await host.close();
    });

    test('the plugin channel reaches the process state and its stateChanged events', () async {
      final channel = host.channel;
      expect(channel.state.value.status, PluginProcessStatus.running);

      final initial = await channel.call('getState') as Map;
      expect(initial['device'], 'quest3');
      expect(initial['refresh_rate_hz'], 90.0);

      final changed = channel.events('stateChanged').first;
      final r = await host.call(PluginMethods.mcpTool, {
        'tool': 'lumina_plugin_metaxr.simulate_pinch',
        'arguments': {'hand': 'right', 'finger': 'index', 'strength': 0.9},
      });
      expect(McpToolResult.fromJson((r as Map).cast()).structuredContent!['is_pinching'], isTrue);
      final event = await changed;
      expect(((event.data as Map)['hands'] as Map)['right'], containsPair('is_pinching', true));
      expect(process.state.rightHand.pinch.isIndexPinching, isTrue);
    });
  });
}
