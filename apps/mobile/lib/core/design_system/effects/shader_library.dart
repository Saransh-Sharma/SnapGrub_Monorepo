import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Every runtime effect the app ships. Keep in sync with pubspec `shaders:`.
enum SgShader {
  metalSheen('shaders/metal_sheen.frag'),
  holoFoil('shaders/holo_foil.frag'),
  liquidRing('shaders/liquid_ring.frag'),
  ripple('shaders/ripple.frag'),
  scanBeam('shaders/scan_beam.frag'),
  dissolve('shaders/dissolve.frag'),
  meshAurora('shaders/mesh_aurora.frag'),
  liquidGlass('shaders/liquid_glass.frag'),
  refractiveGlass('shaders/refractive_glass.frag'),
  mealReveal('shaders/meal_reveal.frag');

  const SgShader(this.asset);
  final String asset;
}

/// Loads and caches [ui.FragmentProgram]s. Programs are preloaded during the
/// splash so the first use of an effect never stalls a frame.
class ShaderLibrary {
  ShaderLibrary._();

  static final Map<SgShader, ui.FragmentProgram> _programs = {};
  static final Map<SgShader, Future<ui.FragmentProgram?>> _pending = {};
  static final Set<SgShader> _failed = {};

  /// Synchronous access; null until loaded (or if loading failed).
  static ui.FragmentProgram? maybe(SgShader shader) => _programs[shader];

  static bool hasFailed(SgShader shader) => _failed.contains(shader);

  static Future<ui.FragmentProgram?> load(SgShader shader) {
    final ready = _programs[shader];
    if (ready != null) return SynchronousFuture(ready);
    return _pending.putIfAbsent(shader, () async {
      try {
        final program = await ui.FragmentProgram.fromAsset(shader.asset);
        _programs[shader] = program;
        return program;
      } catch (error) {
        _failed.add(shader);
        debugPrint('SnapGrub effect ${shader.name} unavailable: $error');
        return null;
      } finally {
        _pending.remove(shader);
      }
    });
  }

  /// Loads every program and performs a tiny warm-up draw per shader so the
  /// pipeline is compiled before it is needed on screen.
  static Future<void> preloadAll() async {
    await Future.wait(SgShader.values.map(load));
    for (final program in _programs.values) {
      try {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final shader = program.fragmentShader();
        // Uniforms default to zero; a 1x1 draw is enough to warm the pipeline.
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 1, 1),
          ui.Paint()..shader = shader,
        );
        recorder.endRecording().dispose();
        shader.dispose();
      } catch (_) {
        // Sampler shaders cannot be drawn without a bound image; skip.
      }
    }
  }
}
