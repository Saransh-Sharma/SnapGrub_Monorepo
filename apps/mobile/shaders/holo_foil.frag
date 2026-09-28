#version 460 core
#include <flutter/runtime_effect.glsl>

// Thin-film holographic foil overlay. Output is a translucent, premultiplied
// overlay meant to be composited over a card surface.
precision highp float;

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uTime;
layout(location = 2) uniform vec2 uTilt;
layout(location = 3) uniform float uIntensity;

layout(location = 0) out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
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

vec3 spectrum(float t) {
  return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / max(uSize.y, 1.0);
  vec2 q = vec2(uv.x * aspect, uv.y);

  float film = dot(q, vec2(0.8, 0.6)) * 1.6
      + uTilt.x * 0.55 + uTilt.y * 0.35
      + noise(q * 3.0 + uTime * 0.05) * 0.35;
  vec3 color = spectrum(film);

  // Bright diagonal band that follows the tilt like a specular sheet.
  float bandPos = 0.5 + uTilt.x * 0.45 - uTilt.y * 0.25;
  float d = (uv.x * 0.7 + uv.y * 0.3) - bandPos;
  float band = exp(-d * d * 18.0);

  // Diffraction sparkles: soft round glints (not square cells).
  vec2 cellUv = frag / 11.0;
  vec2 cell = floor(cellUv);
  vec2 inCell = fract(cellUv) - 0.5;
  float h = hash21(cell);
  vec2 jitter = vec2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5;
  float glint = 1.0 - smoothstep(0.02, 0.22, length(inCell - jitter * 0.5));
  float twinkle = step(0.972, h) * glint *
      pow(0.5 + 0.5 * sin(h * 60.0 + (uTilt.x + uTilt.y) * 14.0 + uTime * 2.0), 4.0);

  float alpha = clamp((0.16 + band * 0.34) * uIntensity + twinkle * 0.6 * uIntensity, 0.0, 0.85);
  vec3 col = mix(color, vec3(1.0), twinkle * 0.8 + band * 0.25);
  fragColor = vec4(col * alpha, alpha);
}
