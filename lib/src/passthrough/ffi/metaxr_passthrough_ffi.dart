// ignore_for_file: non_constant_identifier_names
/// The passthrough's C API (`src/metaxr_passthrough_c.h`), resolved from the
/// `metaxr_passthrough` code asset the hook builds.
@DefaultAsset('package:lumina_plugin_metaxr/metaxr_passthrough.dart')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// `metaxr_passthrough_style`.
final class MetaxrPassthroughStyleNative extends Struct {
  @Float()
  external double opacity;
  @Array(4)
  external Array<Float> edgeColor;
  @Float()
  external double brightness;
  @Float()
  external double contrast;
  @Float()
  external double saturation;
}

@Native<Int32 Function(Pointer<Void>, Uint64, Uint64, Bool)>()
external int metaxr_passthrough_create(Pointer<Void> getInstanceProcAddr, int instance, int session, bool running);

@Native<Int32 Function(Int32, Bool)>()
external int metaxr_passthrough_layer_create(int purpose, bool running);

@Native<Int32 Function()>()
external int metaxr_passthrough_start();

@Native<Int32 Function()>()
external int metaxr_passthrough_pause();

@Native<Int32 Function()>()
external int metaxr_passthrough_layer_resume();

@Native<Int32 Function()>()
external int metaxr_passthrough_layer_pause();

@Native<Int32 Function(Pointer<MetaxrPassthroughStyleNative>)>()
external int metaxr_passthrough_set_style(Pointer<MetaxrPassthroughStyleNative> style);

@Native<Pointer<Void> Function()>()
external Pointer<Void> metaxr_passthrough_layer_header();

@Native<Void Function()>()
external void metaxr_passthrough_destroy();

@Native<Pointer<Utf8> Function()>()
external Pointer<Utf8> metaxr_passthrough_last_error();
