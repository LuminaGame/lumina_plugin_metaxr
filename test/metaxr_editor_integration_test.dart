import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_editor_api/lumina_editor_api.dart';
import 'package:lumina_plugin_metaxr/lumina_plugin_metaxr.dart';

class _TestEditorContext implements LuminaEditorContext {
  final List<String> registeredMenuPaths = [];
  final List<EditorCommand> registeredCommands = [];
  final List<EditorSlotButton> registeredSlotButtons = [];
  final List<EditorMenuItemOptions> registeredMenuOptions = [];

  @override
  void registerMenuItem(String menuPath, EditorCommand command,
      {EditorMenuItemOptions options = const EditorMenuItemOptions()}) {
    registeredMenuPaths.add(menuPath);
    registeredCommands.add(command);
    registeredMenuOptions.add(options);
  }

  @override
  void registerMenu(EditorMenuDescriptor menu) {}

  @override
  void registerToolbarButton(EditorToolbarButton button) {}

  @override
  void registerSlotButton(EditorSlotButton button) {
    registeredSlotButtons.add(button);
  }

  @override
  final EditorPanels panels = EditorPanels.detached();

  @override
  final EditorMcp mcp = EditorMcp.detached(pluginName: 'lumina_plugin_metaxr');

  @override
  final PluginStorage storage = PluginStorage(
      userDir: Directory('${Directory.systemTemp.path}/lumina_metaxr_test_storage'));

  @override
  void registerProjectSettingsSection(ProjectSettingsSection section) {}

  @override
  final ValueNotifier<Map<String, Object?>> pluginSettings = ValueNotifier(const {});

  @override
  void registerPanel(EditorPanelDescriptor panel) {}

  @override
  void registerAssetType(EditorAssetTypeHandler handler) {}

  @override
  void registerImporter(EditorImporter importer) {}

  @override
  void registerDetailsCustomization(DetailsCustomization c) {}

  @override
  void registerConsoleCommand(String name, String help, void Function(List<String> args) handler) {}
}

void main() {
  group('MetaXR Editor Integration Tests', () {
    test('LuminaPluginMetaxrPlugin registers menus and MCP tools', () async {
      final plugin = LuminaPluginMetaxrPlugin();
      final ctx = _TestEditorContext();

      plugin.register(ctx);

      expect(ctx.registeredMenuPaths, contains('Plugins/MetaXR/MetaXR Settings'));
      expect(ctx.registeredMenuPaths, contains('Plugins/MetaXR/Simulation Panel'));
      expect(ctx.registeredMenuPaths, contains('Plugins/MetaXR/Calibrate Anchors'));
      expect(ctx.registeredMenuPaths, contains('Plugins/MetaXR/About MetaXR Support'));

      // Test MCP get_capabilities
      final capResult = await ctx.mcp.callTool('lumina_plugin_metaxr.get_capabilities', {});
      expect(capResult.structuredContent, isNotNull);
      expect(capResult.structuredContent!['device_model'], isNotNull);
      expect(capResult.structuredContent!['refresh_rate_hz'], isNotNull);

      // Test MCP simulate_pinch
      final pinchResult = await ctx.mcp.callTool('lumina_plugin_metaxr.simulate_pinch', {
        'hand': 'right',
        'finger': 'index',
        'strength': 0.9,
      });
      expect(pinchResult.structuredContent, isNotNull);
      expect(pinchResult.structuredContent!['is_pinching'], isTrue);
      expect(plugin.rightHand.pinch.isIndexPinching, isTrue);
    });
  });
}
