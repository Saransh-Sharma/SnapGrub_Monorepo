#version 460 core
#include <flutter/runtime_effect.glsl>

// Slow four-point mesh gradient with film grain. Opaque background layer.
precision highp float;

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uTime;
layout(location = 2) uniform vec3 uC1;
layout(location = 3) uniform vec3 uC2;
layout(location = 4) uniform vec3 uC3;
layout(location = 5) uniform vec3 uC4;
layout(location = 6) uniform float uGrain;
layout(location = 7) uniform float uOpacity;

layout(location = 0) out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(443.897, 441.423));
  p += dot(p, p + 19.19);
  return fract(p.x * p.y);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float t = uTime * 0.06;

  vec2 p1 = vec2(0.15 + 0.10 * sin(t * 1.1), 0.12 + 0.08 * cos(t * 0.9));
  vec2 p2 = vec2(0.88 + 0.08 * cos(t * 0.7), 0.18 + 0.10 * sin(t * 1.3));
  vec2 p3 = vec2(0.20 + 0.12 * cos(t * 0.8), 0.86 + 0.07 * sin(t * 1.2));
  vec2 p4 = vec2(0.82 + 0.09 * sin(t * 1.0), 0.80 + 0.10 * cos(t * 0.6));

  float w1 = 1.0 / (0.02 + pow(distance(uv, p1), 2.2));
  float w2 = 1.0 / (0.02 + pow(distance(uv, p2), 2.2));
  float w3 = 1.0 / (0.02 + pow(distance(uv, p3), 2.2));
  float w4 = 1.0 / (0.02 + pow(distance(uv, p4), 2.2));
  vec3 col = (uC1 * w1 + uC2 * w2 + uC3 * w3 + uC4 * w4) / (w1 + w2 + w3 + w4);

  float grain = (hash21(frag + fract(uTime) * 17.0) - 0.5) * uGrain;
  col += grain;
  float a = clamp(uOpacity, 0.0, 1.0);
  fragColor = vec4(clamp(col, 0.0, 1.0) * a, a);
}
