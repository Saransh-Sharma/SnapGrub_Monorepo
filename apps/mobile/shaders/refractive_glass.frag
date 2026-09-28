#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;
layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uProgress;
layout(location = 0) out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float edge = smoothstep(0.55, 1.0, 1.0 - distance(uv, vec2(0.18, 0.0)));
  float sweep = smoothstep(0.0, 0.18, 1.0 - abs(uv.x - uProgress));
  float alpha = (edge * 0.16) + (sweep * 0.07);
  fragColor = vec4(vec3(alpha), alpha);
}
