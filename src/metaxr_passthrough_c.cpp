// XR_FB_passthrough through the openxr plugin's instance (see metaxr_passthrough_c.h).

#include "metaxr_passthrough_c.h"

#include <cstdio>
#include <string>

#include <openxr/openxr.h>

#if defined(__ANDROID__)
#include <android/log.h>
#endif

namespace {

struct Passthrough {
    PFN_xrGetInstanceProcAddr getProc = nullptr;
    XrInstance instance = XR_NULL_HANDLE;
    XrSession session = XR_NULL_HANDLE;
    XrPassthroughFB passthrough = XR_NULL_HANDLE;
    XrPassthroughLayerFB layer = XR_NULL_HANDLE;
    XrCompositionLayerPassthroughFB header{XR_TYPE_COMPOSITION_LAYER_PASSTHROUGH_FB};
    std::string lastError;
};

Passthrough& pt() {
    static Passthrough p;
    return p;
}

void log(const char* message, int value) {
#if defined(__ANDROID__)
    __android_log_print(ANDROID_LOG_INFO, "LuminaMetaXR", "%s %d", message, value);
#else
    fprintf(stderr, "[LuminaMetaXR] %s %d\n", message, value);
#endif
}

template <typename T>
T fn(const char* name) {
    Passthrough& p = pt();
    PFN_xrVoidFunction f = nullptr;
    if (!p.getProc || p.instance == XR_NULL_HANDLE) return nullptr;
    if (XR_FAILED(p.getProc(p.instance, name, &f))) return nullptr;
    return reinterpret_cast<T>(f);
}

int32_t result(XrResult r, const char* what) {
    log(what, static_cast<int>(r));
    if (XR_FAILED(r)) pt().lastError = std::string(what) + " failed: XrResult " + std::to_string(static_cast<int>(r));
    return static_cast<int32_t>(r);
}

}  // namespace

int32_t metaxr_passthrough_create(void* get_instance_proc_addr, uint64_t instance, uint64_t session, bool running) {
    Passthrough& p = pt();
    p.getProc = reinterpret_cast<PFN_xrGetInstanceProcAddr>(get_instance_proc_addr);
    p.instance = reinterpret_cast<XrInstance>(instance);
    p.session = reinterpret_cast<XrSession>(session);
    auto create = fn<PFN_xrCreatePassthroughFB>("xrCreatePassthroughFB");
    if (!create || p.session == XR_NULL_HANDLE) return result(XR_ERROR_EXTENSION_NOT_PRESENT, "xrCreatePassthroughFB");
    XrPassthroughCreateInfoFB info{XR_TYPE_PASSTHROUGH_CREATE_INFO_FB};
    info.flags = running ? XR_PASSTHROUGH_IS_RUNNING_AT_CREATION_BIT_FB : 0;
    return result(create(p.session, &info, &p.passthrough), "xrCreatePassthroughFB");
}

int32_t metaxr_passthrough_layer_create(int32_t purpose, bool running) {
    Passthrough& p = pt();
    auto create = fn<PFN_xrCreatePassthroughLayerFB>("xrCreatePassthroughLayerFB");
    if (!create || p.passthrough == XR_NULL_HANDLE) return result(XR_ERROR_HANDLE_INVALID, "xrCreatePassthroughLayerFB");
    XrPassthroughLayerCreateInfoFB info{XR_TYPE_PASSTHROUGH_LAYER_CREATE_INFO_FB};
    info.passthrough = p.passthrough;
    info.flags = running ? XR_PASSTHROUGH_IS_RUNNING_AT_CREATION_BIT_FB : 0;
    info.purpose = purpose == 1 ? XR_PASSTHROUGH_LAYER_PURPOSE_PROJECTED_FB : XR_PASSTHROUGH_LAYER_PURPOSE_RECONSTRUCTION_FB;
    XrResult r = create(p.session, &info, &p.layer);
    p.header = {XR_TYPE_COMPOSITION_LAYER_PASSTHROUGH_FB};
    p.header.flags = XR_COMPOSITION_LAYER_BLEND_TEXTURE_SOURCE_ALPHA_BIT;
    p.header.space = XR_NULL_HANDLE;
    p.header.layerHandle = p.layer;
    return result(r, "xrCreatePassthroughLayerFB");
}

int32_t metaxr_passthrough_start(void) {
    auto f = fn<PFN_xrPassthroughStartFB>("xrPassthroughStartFB");
    return f ? result(f(pt().passthrough), "xrPassthroughStartFB") : result(XR_ERROR_HANDLE_INVALID, "xrPassthroughStartFB");
}

int32_t metaxr_passthrough_pause(void) {
    auto f = fn<PFN_xrPassthroughPauseFB>("xrPassthroughPauseFB");
    return f ? result(f(pt().passthrough), "xrPassthroughPauseFB") : result(XR_ERROR_HANDLE_INVALID, "xrPassthroughPauseFB");
}

int32_t metaxr_passthrough_layer_resume(void) {
    auto f = fn<PFN_xrPassthroughLayerResumeFB>("xrPassthroughLayerResumeFB");
    return f ? result(f(pt().layer), "xrPassthroughLayerResumeFB") : result(XR_ERROR_HANDLE_INVALID, "xrPassthroughLayerResumeFB");
}

int32_t metaxr_passthrough_layer_pause(void) {
    auto f = fn<PFN_xrPassthroughLayerPauseFB>("xrPassthroughLayerPauseFB");
    return f ? result(f(pt().layer), "xrPassthroughLayerPauseFB") : result(XR_ERROR_HANDLE_INVALID, "xrPassthroughLayerPauseFB");
}

int32_t metaxr_passthrough_set_style(const metaxr_passthrough_style* style) {
    auto f = fn<PFN_xrPassthroughLayerSetStyleFB>("xrPassthroughLayerSetStyleFB");
    if (!f || !style || pt().layer == XR_NULL_HANDLE) return result(XR_ERROR_HANDLE_INVALID, "xrPassthroughLayerSetStyleFB");
    XrPassthroughBrightnessContrastSaturationFB bcs{XR_TYPE_PASSTHROUGH_BRIGHTNESS_CONTRAST_SATURATION_FB};
    bcs.brightness = style->brightness;
    bcs.contrast = style->contrast;
    bcs.saturation = style->saturation;
    XrPassthroughStyleFB s{XR_TYPE_PASSTHROUGH_STYLE_FB};
    s.next = &bcs;
    s.textureOpacityFactor = style->opacity;
    s.edgeColor = {style->edge_color[0], style->edge_color[1], style->edge_color[2], style->edge_color[3]};
    return result(f(pt().layer, &s), "xrPassthroughLayerSetStyleFB");
}

const void* metaxr_passthrough_layer_header(void) {
    return pt().layer == XR_NULL_HANDLE ? nullptr : &pt().header;
}

void metaxr_passthrough_destroy(void) {
    Passthrough& p = pt();
    if (p.layer != XR_NULL_HANDLE) {
        if (auto f = fn<PFN_xrDestroyPassthroughLayerFB>("xrDestroyPassthroughLayerFB")) f(p.layer);
        p.layer = XR_NULL_HANDLE;
    }
    if (p.passthrough != XR_NULL_HANDLE) {
        if (auto f = fn<PFN_xrDestroyPassthroughFB>("xrDestroyPassthroughFB")) f(p.passthrough);
        p.passthrough = XR_NULL_HANDLE;
    }
    p.header.layerHandle = XR_NULL_HANDLE;
}

const char* metaxr_passthrough_last_error(void) { return pt().lastError.c_str(); }
