#version 460 core
#include <flutter/runtime_effect.glsl>

// Damped radial ripple displacement of the child texture.
precision highp float;

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uProgress; // 0..1
layout(location = 2) uniform vec2 uCenter;    // px
layout(location = 3) uniform float uAmplitude; // px
uniform sampler2D uTexture;

layout(location = 0) out vec4 fragColor;

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  vec2 delta = frag - uCenter;
  float d = length(delta);
  float maxR = length(uSize) * 0.9;
  float front = uProgress * maxR;
  float x = d - front;
  float envelope = exp(-abs(x) * 0.045) * (1.0 - uProgress);
  float offset = sin(x * 0.22) * uAmplitude * envelope;
  vec2 dir = d > 0.001 ? delta / d : vec2(0.0);
  vec2 sampleUv = (frag - dir * offset) / uSize;
  vec4 color = texture(uTexture, clamp(sampleUv, vec2(0.0), vec2(1.0)));
  color.rgb += color.a * vec3(0.10) * max(sin(x * 0.22), 0.0) * envelope;
  fragColor = color;
}
