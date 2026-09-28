#version 460 core
#include <flutter/runtime_effect.glsl>

// Progress ring with a liquid meniscus at the fill head and a slow internal
// caustic shimmer. Progress > 1 draws the overflow lap in uOverColor.
precision highp float;

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uTime;
layout(location = 2) uniform float uProgress;
layout(location = 3) uniform float uThickness; // stroke width / radius
layout(location = 4) uniform float uWobble;    // 0..1 impulse, decays in Dart
layout(location = 5) uniform vec3 uColor;
layout(location = 6) uniform vec4 uTrack;      // premultiplied not required
layout(location = 7) uniform vec3 uOverColor;

layout(location = 0) out vec4 fragColor;

const float PI = 3.14159265;

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float radius = 0.5 * min(uSize.x, uSize.y);
  vec2 p = (frag - 0.5 * uSize) / radius;
  float r = length(p);
  float aa = 1.5 / radius;

  float outer = 1.0 - aa;
  float inner = outer - uThickness;
  float band = smoothstep(inner - aa, inner + aa, r) *
      (1.0 - smoothstep(outer - aa, outer + aa, r));
  if (band <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // Angle from 12 o'clock, clockwise, 0..1.
  float a = atan(p.x, -p.y) / (2.0 * PI);
  a = fract(a + 1.0);

  float local = (r - inner) / max(uThickness, 0.0001); // 0..1 across stroke
  float wave = sin(local * 2.0 * PI + uTime * 5.0) * (0.006 + 0.03 * uWobble)
      + sin(local * 5.0 * PI - uTime * 7.0) * 0.004 * (0.5 + uWobble);

  float progress = clamp(uProgress, 0.0, 2.0);
  float lap1 = min(progress, 1.0);
  float lap2 = max(progress - 1.0, 0.0);
  float headAa = aa / (2.0 * PI);

  float fill1 = 1.0 - smoothstep(lap1 + wave - headAa, lap1 + wave + headAa, a);
  if (lap1 >= 0.999) fill1 = 1.0;
  float fill2 = lap2 > 0.0
      ? 1.0 - smoothstep(lap2 + wave - headAa, lap2 + wave + headAa, a)
      : 0.0;

  // Caustics: gentle bright ripples travelling along the filled arc.
  float caustic = 0.5 + 0.5 * sin(a * 48.0 - uTime * 2.4 + sin(local * 6.0 + uTime) * 1.5);
  float head = exp(-pow((a - lap1) * 26.0, 2.0)) * step(a, lap1 + 0.02);
  vec3 liquid = uColor * (0.9 + 0.12 * caustic) + vec3(0.18) * head;
  // Soft inner highlight along the outer edge of the stroke.
  liquid += vec3(0.10) * smoothstep(0.55, 1.0, local);

  vec3 col = uTrack.rgb;
  float alpha = uTrack.a;
  col = mix(col, liquid, fill1);
  alpha = mix(alpha, 1.0, fill1);
  col = mix(col, uOverColor, fill2);

  alpha *= band;
  fragColor = vec4(col * alpha, alpha);
}
