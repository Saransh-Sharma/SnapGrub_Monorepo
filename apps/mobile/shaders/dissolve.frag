#version 460 core
#include <flutter/runtime_effect.glsl>

// Directional noise dissolve with a glowing edge. uProgress 0 = intact,
// 1 = gone. Reversing the progress reverses the effect (used by Undo).
precision highp float;

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uProgress;
layout(location = 2) uniform vec2 uDirection;
layout(location = 3) uniform vec3 uEdgeColor;
uniform sampler2D uTexture;

layout(location = 0) out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(233.34, 851.73));
  p += dot(p, p + 23.45);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
             mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
             u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 4; i++) {
    v += amp * noise(p);
    p *= 2.03;
    amp *= 0.5;
  }
  return v;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  vec2 dir = normalize(uDirection + vec2(0.00001));
  float aspect = uSize.x / max(uSize.y, 1.0);
  float n = fbm(vec2(uv.x * aspect, uv.y) * 9.0);
  float g = dot(uv - 0.5, dir) + 0.5;
  float v = n * 0.45 + (1.0 - g) * 0.55;
  float threshold = uProgress * 1.25 - 0.1;

  // Grains drift in the swipe direction as they dissolve.
  vec2 drift = dir * uProgress * 0.06 * n;
  vec4 color = texture(uTexture, clamp(uv - drift, vec2(0.0), vec2(1.0)));

  float keep = smoothstep(threshold - 0.015, threshold + 0.015, v);
  float edge = (1.0 - smoothstep(0.0, 0.05, abs(v - threshold))) * step(0.001, uProgress);
  vec3 rgb = color.rgb + uEdgeColor * edge * color.a;
  float a = color.a * max(keep, edge * 0.8);
  fragColor = vec4(rgb * (a / max(color.a, 0.0001)), a);
}
