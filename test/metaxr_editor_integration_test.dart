import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_editor_api/lumina_editor_api.dart';
import 'package:lumina_editor_api/testing.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';

/// The editor context the in-process shell is registered with; its process
/// channel is the [LoopbackHost]'s, so calls reach a real [MetaXrProcess].
class _TestEditorContext implements LuminaEditorContext {
  _TestEditorContext(this.channel);

  final PluginProcessChannel channel;
  final List<String> registered = [];
  final List<String> channelRequests = [];

  @override
  PluginProcessChannel processChannel(String pluginName) {
    channelRequests.add(pluginName);
    return channel;
  }

  @override
  void registerMenuItem(String menuPath, EditorCommand command,
          {EditorMenuItemOptions options = const EditorMenuItemOptions()}) =>
      registered.add('menuItem $menuPath');

  @override
  void registerMenu(EditorMenuDescriptor menu) => registered.add('menu ${menu.id}');

  @override
  void registerToolbarButton(EditorToolbarButton button) => registered.add('toolbar ${button.id}');

  @override
  void registerSlotButton(EditorSlotButton button) => registered.add('slot ${button.id}');

  @override
  final EditorPanels panels = EditorPanels.detached();

  @override
  final EditorMcp mcp = EditorMcp.detached(pluginName: 'lumina_plugin_metaxr');

  @override
  final PluginStorage storage =
      PluginStorage(userDir: Directory('${Directory.systemTemp.path}/lumina_metaxr_test_storage'));

  @override
  void registerProjectSettingsSection(ProjectSettingsSection section) => registered.add('settings ${section.id}');

  @override
  final ValueNotifier<Map<String, Object?>> pluginSettings = ValueNotifier(const {});

  @override
  void registerPanel(EditorPanelDescriptor panel) => registered.add('panel ${panel.id}');

  @override
  void registerTab(EditorTabDescriptor tab) => registered.add('tab ${tab.id}');

  @override
  void openTab(String tabId, {String? title}) {}

  @override
  void registerAssetType(EditorAssetTypeHandler handler) => registered.add('assetType');

  @override
  void registerImporter(EditorImporter importer) => registered.add('importer ${importer.description}');

  @override
  void registerDetailsCustomization(DetailsCustomization c) => registered.add('details');

  @override
  void registerConsoleCommand(String name, String help, void Function(List<String> args) handler) =>
      registered.add('console $name');

  @override
  Future<void> saveAsset({required String relativePath, Uint8List? bytes, bool generateThumbnail = true}) async {}

  @override
  void reportCrash(Object error, StackTrace? stack, {String? plugin, String? context}) {}
}

void main() {
  group('MetaXR editor integration', () {
    late LoopbackHost host;
    late Future<int> exit;
    late MetaXrProcess process;

    setUp(() async {
      host = await LoopbackHost.start();
      process = MetaXrProcess();
      exit = runPluginProcessMain(host.launch(MetaXrViews.pluginName), process);
      await host.contributions;
    });

    tearDown(() async {
      await host.call(PluginMethods.shutdown);
      expect(await exit, PluginProcessExitCodes.ok);
      await host.close();
    });

    test('the in-process shell registers nothing: every contribution comes from the process', () async {
      final shell = LuminaPluginMetaxrPlugin();
      final ctx = _TestEditorContext(host.channel);
      shell.register(ctx);
      expect(shell.pluginName, process.pluginName);
      expect(ctx.registered, isEmpty);

      final contributions = await host.contributions;
      expect(contributions.menuItems.map((i) => i.path), contains('Plugins/MetaXR/About MetaXR Support'));
      expect(contributions.panels, hasLength(3));
      expect(contributions.mcpTools, hasLength(2));
    });

    test('the plugin channel reaches the process state and its stateChanged events', () async {
      final ctx = _TestEditorContext(host.channel);
      final channel = ctx.processChannel(MetaXrViews.pluginName);
      expect(ctx.channelRequests, [MetaXrViews.pluginName]);
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
