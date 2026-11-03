#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// The Descent's night grade, on every room painting (`DescentBackdrop`).
///
/// The pen-and-ink paintings are drawn on pale paper; a black veil over them
/// only turned the paper grey. This takes the paper and the stone down into a
/// cool slate dark instead, and keeps the colour of whatever is warm, saturated
/// and bright — the fire, the lava, a lit torch — so it reads as the only light
/// in the room. `exposure` brings every painting to about the same depth
/// (`DescentStyle.nightExposure`). Colours arrive premultiplied.
[[ stitchable ]] half4 descentNightGrade(float2 position, half4 color, float exposure) {
    if (color.a <= 0.0h) {
        return color;
    }
    half3 c = color.rgb / color.a;

    // Paper and stone: a little less colour, then the slate tint.
    half luma = dot(c, half3(0.2126h, 0.7152h, 0.0722h));
    half3 night = (luma + (c - luma) * 0.7h) * half3(0.37h, 0.41h, 0.53h) * half(exposure);

    // Fire and lava: saturated, bright and warm (red at least as high as green, well above blue).
    half hi = max(c.r, max(c.g, c.b));
    half lo = min(c.r, min(c.g, c.b));
    half saturation = hi > 0.0h ? (hi - lo) / hi : 0.0h;
    half warmth = saturate((c.r - c.b) * 2.2h) * step(c.g, c.r);
    half lit = smoothstep(0.38h, 0.7h, saturation) * smoothstep(0.5h, 0.85h, hi) * warmth;

    return half4(mix(night, c, lit) * color.a, color.a);
}
