#version 460 core
#include <flutter/runtime_effect.glsl>

// Analysis scan: a sweeping light plane that lights up food edges (Sobel on
// luminance) plus a dot grid that fades as confidence rises.
precision highp float;

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uTime;       // seconds
layout(location = 2) uniform float uConfidence; // 0..1
layout(location = 3) uniform vec3 uTint;
uniform sampler2D uTexture;

layout(location = 0) out vec4 fragColor;

float luma(vec2 uv) {
  return dot(texture(uTexture, uv).rgb, vec3(0.299, 0.587, 0.114));
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  vec2 px = 1.5 / uSize;
  vec4 base = texture(uTexture, uv);

  float tl = luma(uv + px * vec2(-1.0, -1.0));
  float t = luma(uv + px * vec2(0.0, -1.0));
  float tr = luma(uv + px * vec2(1.0, -1.0));
  float l = luma(uv + px * vec2(-1.0, 0.0));
  float rr = luma(uv + px * vec2(1.0, 0.0));
  float bl = luma(uv + px * vec2(-1.0, 1.0));
  float b = luma(uv + px * vec2(0.0, 1.0));
  float br = luma(uv + px * vec2(1.0, 1.0));
  float gx = -tl - 2.0 * l - bl + tr + 2.0 * rr + br;
  float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
  float edge = smoothstep(0.18, 0.6, sqrt(gx * gx + gy * gy));

  // Ping-pong beam position.
  float cycle = fract(uTime * 0.42);
  float beamY = abs(cycle * 2.0 - 1.0);
  float dist = uv.y - beamY;
  float beam = exp(-dist * dist * 2600.0);
  float wake = exp(-abs(dist) * 9.0);

  float grid = 0.0;
  vec2 cell = mod(frag, 14.0) - 7.0;
  grid = (1.0 - smoothstep(0.6, 1.4, length(cell))) * (1.0 - uConfidence) * 0.35;

  vec3 col = base.rgb * (0.86 + 0.14 * wake);
  col += uTint * edge * wake * 0.85;
  col += mix(uTint, vec3(1.0), 0.6) * beam * 0.9;
  col += vec3(1.0) * grid * (0.4 + 0.6 * wake);
  fragColor = vec4(clamp(col, 0.0, 1.0) * base.a, base.a);
}
