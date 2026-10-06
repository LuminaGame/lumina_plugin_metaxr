/// The name, display name and version of MetaXR Support, shared by the
/// in-process shell and the plugin process. Imports nothing, so the shell's
/// import graph stays free of the OpenXR bindings.
abstract final class MetaXrInfo {
  static const String pluginName = 'lumina_plugin_metaxr';
  static const String friendlyName = 'MetaXR Support';
  static const String version = '0.2.0';
}
