#version 460 core
#include <flutter/runtime_effect.glsl>

// Brushed / spun metal material with a tilt-driven specular highlight.
// Painted as a Paint.shader, so it can fill any path (disc, ring, rrect).
//
// uMode: 0 = planar (linear brushing, cylindrical normal)
//        1 = disc   (spun brushing, dome normal)
//        2 = ring   (spun brushing, torus normal; uRing = centre radius, half width)
precision highp float;

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uTime;
layout(location = 2) uniform vec2 uTilt;
layout(location = 3) uniform vec3 uBase;
layout(location = 4) uniform vec3 uHighlight;
layout(location = 5) uniform vec3 uShadow;
layout(location = 6) uniform float uMode;
layout(location = 7) uniform vec2 uRing;
layout(location = 8) uniform float uGlint;
layout(location = 9) uniform float uOpacity;

layout(location = 0) out vec4 fragColor;

float hash11(float p) {
  p = fract(p * 0.1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

float valueNoise1(float x) {
  float i = floor(x);
  float f = fract(x);
  float u = f * f * (3.0 - 2.0 * f);
  return mix(hash11(i), hash11(i + 1.0), u);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float halfMin = 0.5 * min(uSize.x, uSize.y);
  vec2 p = (frag - 0.5 * uSize) / halfMin; // -1..1 on the short side
  float r = length(p);
  vec2 dir = r > 0.0001 ? p / r : vec2(0.0, -1.0);

  vec3 n;
  float brush;
  if (uMode < 0.5) {
    n = normalize(vec3(0.0, (uv.y - 0.5) * 1.3, 1.0));
    brush = valueNoise1(frag.y * 1.7 + valueNoise1(frag.x * 0.02) * 6.0);
  } else if (uMode < 1.5) {
    float dome = clamp(r, 0.0, 1.0);
    n = normalize(vec3(dir * dome * 0.85, 1.0));
    brush = valueNoise1(r * halfMin * 1.4);
  } else {
    float t = clamp((r - uRing.x) / max(uRing.y, 0.0001), -1.0, 1.0);
    n = normalize(vec3(dir * t * 0.9, sqrt(max(1.0 - t * t, 0.05))));
    brush = valueNoise1(r * halfMin * 1.4);
  }

  vec3 light = normalize(vec3(-0.35 + uTilt.x * 0.9, -0.55 + uTilt.y * 0.9, 1.0));
  vec3 viewDir = vec3(0.0, 0.0, 1.0);
  vec3 halfVec = normalize(light + viewDir);

  float diffuse = clamp(dot(n, light), 0.0, 1.0);
  float spec = pow(clamp(dot(n, halfVec), 0.0, 1.0), 42.0);

  // Anisotropic "bow-tie" highlight typical of spun metal.
  float aniso = 0.0;
  if (uMode > 0.5) {
    vec2 l2 = normalize(light.xy + vec2(0.0001));
    aniso = pow(abs(dot(dir, l2)), 18.0) * 0.55;
  } else {
    aniso = pow(1.0 - abs(uv.y - (0.35 - uTilt.y * 0.25)), 24.0) * 0.45;
  }

  float fresnel = pow(1.0 - clamp(n.z, 0.0, 1.0), 2.5);

  vec3 col = mix(uShadow, uBase, smoothstep(0.05, 0.85, diffuse));
  col = mix(col, uHighlight, clamp(spec + aniso, 0.0, 1.0));
  col += uHighlight * fresnel * 0.18;
  col *= 0.93 + brush * 0.12;

  // Optional travelling glint (uGlint in 0..1 sweeps, < 0 disables).
  if (uGlint >= 0.0) {
    float band = (uv.x + uv.y) * 0.5 - (uGlint * 1.6 - 0.3);
    float glint = exp(-band * band * 900.0) * 0.85;
    col = mix(col, vec3(1.0), glint);
  }

  // Subtle idle breathing so large metal surfaces never look static.
  col *= 1.0 + 0.025 * sin(uTime * 1.3);

  float a = clamp(uOpacity, 0.0, 1.0);
  fragColor = vec4(clamp(col, 0.0, 1.0) * a, a);
}
