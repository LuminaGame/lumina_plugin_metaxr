#ifndef METAXR_PASSTHROUGH_C_H
#define METAXR_PASSTHROUGH_C_H

// XR_FB_passthrough on the openxr plugin's instance and session: the
// passthrough feature, one layer, start / pause / resume, style, and the
// XrCompositionLayerPassthroughFB the openxr frame loop submits. The
// functions come from the openxr plugin's xrGetInstanceProcAddr
// (openxr_bridge_get_instance_proc_addr); nothing links an OpenXR loader.

#include <stdbool.h>
#include <stdint.h>

#if defined(_WIN32)
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// The style of the layer: XrPassthroughStyleFB plus the
/// XrPassthroughBrightnessContrastSaturationFB chained in its `next`.
typedef struct metaxr_passthrough_style {
    float opacity;
    /// Edge colour (RGBA); alpha 0 draws no edges.
    float edge_color[4];
    /// -100..100 (0: unchanged).
    float brightness;
    /// 0.. (1: unchanged).
    float contrast;
    /// 0.. (1: unchanged).
    float saturation;
} metaxr_passthrough_style;

/// xrCreatePassthroughFB on [session] of [instance] (handles as integers),
/// with functions from [get_instance_proc_addr]. [running]: the feature runs
/// from creation. Returns an XrResult.
FFI_PLUGIN_EXPORT int32_t metaxr_passthrough_create(void* get_instance_proc_addr, uint64_t instance, uint64_t session,
        bool running);
/// xrCreatePassthroughLayerFB: [purpose] 0 reconstruction, 1 projected surface.
FFI_PLUGIN_EXPORT int32_t metaxr_passthrough_layer_create(int32_t purpose, bool running);
FFI_PLUGIN_EXPORT int32_t metaxr_passthrough_start(void);
FFI_PLUGIN_EXPORT int32_t metaxr_passthrough_pause(void);
FFI_PLUGIN_EXPORT int32_t metaxr_passthrough_layer_resume(void);
FFI_PLUGIN_EXPORT int32_t metaxr_passthrough_layer_pause(void);
/// xrPassthroughLayerSetStyleFB.
FFI_PLUGIN_EXPORT int32_t metaxr_passthrough_set_style(const metaxr_passthrough_style* style);
/// The XrCompositionLayerPassthroughFB of the layer (stable until destroy), or null.
FFI_PLUGIN_EXPORT const void* metaxr_passthrough_layer_header(void);
/// Destroys the layer and the feature.
FFI_PLUGIN_EXPORT void metaxr_passthrough_destroy(void);
/// The last failure ("" when none).
FFI_PLUGIN_EXPORT const char* metaxr_passthrough_last_error(void);

#ifdef __cplusplus
}
#endif

#endif  // METAXR_PASSTHROUGH_C_H
