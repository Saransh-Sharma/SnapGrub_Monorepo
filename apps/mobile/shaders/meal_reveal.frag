#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;
layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uProgress;
layout(location = 0) out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float grain = hash(floor(uv * uSize / 5.0)) * 0.10;
  float threshold = clamp(uProgress + grain, 0.0, 1.0);
  // Begin with a soft porcelain veil and clear it from top to bottom. Keeping
  // the terminal alpha at zero is important: this shader is composited over
  // the artwork rather than sampling and replacing it.
  float alpha = 1.0 - smoothstep(uv.y - 0.08, uv.y + 0.08, threshold);
  fragColor = vec4(vec3(alpha), alpha);
}
