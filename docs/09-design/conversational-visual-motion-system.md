# Conversational visual and motion system

## Direction

The interface uses porcelain, paper, and ink foundations with deep sage actions
and sparing persimmon accents. Macro colors are informational, never decorative.
Instrument Serif is bundled under the OFL for meal and atlas titles; interface
copy stays in the platform system sans.

Content cards are opaque and calm. Glass is limited to navigation, the date
capsule, composer, and transient controls. Dark mode maps porcelain to warm
charcoal rather than pure black.

## Tokens

- Spacing follows a compact 4/8/12/16/24/32 rhythm.
- Card radii are 20–24 points; transient navigation surfaces use 18–22 points.
- Press: 120 ms, settle: 260 ms, page: 430 ms, reveal: 520 ms.
- Standard movement uses an ease-out cubic curve. Emphasized arrivals may use a
  restrained ease-out-back curve without overshoot on text.

The source of truth is `apps/mobile/lib/app/theme/design_tokens.dart` and
`premium_motion.dart`.

## Runtime effects

`refractive_glass.frag` adds a low-alpha moving edge light to navigation glass.
`meal_reveal.frag` adds a fine-grained vertical reveal as generated art arrives.
Both are Flutter fragment programs executed through Impeller on iOS. Failure to
load a shader leaves the base UI intact. Reduce Motion omits the effects, and
Increased Contrast removes blur and uses opaque fills.

## Image art direction

Prompt style `studio-v1` requests a 4:5 editorial studio photograph on warm pale
stone with soft daylight, elevated three-quarter framing, believable portions,
and no people, hands, text, packaging, labels, logos, borders, or watermarks.
Canonical meal components form the prompt signature. Existing images are lazy;
new confirmed meals are queued immediately. A deterministic illustrated plate
remains attractive and identifiable while generation is unavailable.
Conversation cards label an active generation state; atlas tiles keep only the
light sweep so transient status never competes with editorial title metadata.
