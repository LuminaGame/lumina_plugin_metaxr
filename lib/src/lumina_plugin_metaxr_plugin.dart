import 'package:lumina_editor_api/lumina_editor_api.dart';

import 'metaxr_info.dart';

/// The in-process part of MetaXR Support (the `.lmplugin`
/// `registration_class`).
///
/// The plugin runs in its own process (`"isolation": "process"`): its menu
/// commands, MCP tools, level access and its three panels (declarative
/// `PluginViewSpec`s the editor renders) are all registered by
/// `MetaXrProcess`, the module's `process_class`. Nothing of it builds
/// widgets, so this shell registers nothing; it exists because the manifest
/// names a registration class for every editor module.
class LuminaPluginMetaxrPlugin extends LuminaEditorPlugin {
  static const String friendlyName = MetaXrInfo.friendlyName;
  static const String version = MetaXrInfo.version;

  @override
  String get pluginName => MetaXrInfo.pluginName;

  @override
  void register(LuminaEditorContext context) {}
}
