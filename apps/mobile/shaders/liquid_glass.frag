#version 460 core
#include <flutter/runtime_effect.glsl>

// Backdrop lens used with ImageFilter.shader inside a BackdropFilter.
// Magnifies and bends the backdrop near the rounded edges, adds a hint of
// chromatic dispersion and a specular top rim.
precision highp float;

layout(location = 0) uniform vec2 uSize;     // set by engine: texture size
layout(location = 1) uniform vec4 uRect;     // lens rect in texture px (l, t, w, h)
layout(location = 2) uniform float uRadius;  // corner radius px
layout(location = 3) uniform float uStrength;
uniform sampler2D uTexture;

layout(location = 0) out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
  frag.y = uSize.y - frag.y;
#endif
  vec2 center = uRect.xy + 0.5 * uRect.zw;
  vec2 halfSize = 0.5 * uRect.zw;
  vec2 local = frag - center;
  float sd = sdRoundBox(local, halfSize, uRadius);

  if (sd > 0.0) {
    fragColor = texture(uTexture, uv);
    return;
  }

  // 0 at the edge, 1 deep inside.
  float depth = clamp(-sd / max(min(halfSize.x, halfSize.y) * 0.9, 1.0), 0.0, 1.0);
  float bend = pow(1.0 - depth, 2.4) * uStrength;
  vec2 dir = normalize(local + vec2(0.0001));
  vec2 offset = -dir * bend * 18.0;

  vec2 texel = 1.0 / uSize;
  float r = texture(uTexture, uv + (offset * 1.08) * texel).r;
  float g = texture(uTexture, uv + offset * texel).g;
  float b = texture(uTexture, uv + (offset * 0.92) * texel).b;
  vec3 col = vec3(r, g, b);

  // Specular rim, brighter on the top edge.
  float rim = (1.0 - smoothstep(0.0, 2.2, -sd));
  float top = clamp(-local.y / halfSize.y, 0.0, 1.0);
  col += vec3(1.0) * rim * (0.10 + 0.35 * top);
  // Gentle milk so text on top stays legible.
  col = mix(col, vec3(1.0), 0.06);
  fragColor = vec4(col, 1.0);
}
