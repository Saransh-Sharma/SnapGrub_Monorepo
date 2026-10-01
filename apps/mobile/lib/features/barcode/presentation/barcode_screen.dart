import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/barcode/data/label_text_recognizer.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

/// Scan a packaged food. A match opens the meal editor; a miss offers a
/// short custom-product form or a nutrition-label scan instead.
class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends ConsumerState<BarcodeScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String? _barcode;

  /// Why the product wasn't found (shown on the fallback form).
  String? _notFoundReason;

  /// Any other error: lookup failed, label scan failed, etc.
  String? _error;
  String? _nameError;
  bool _handling = false;
  bool _notFound = false;

  @override
  void dispose() {
    _scanner.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  bool get _isE2e => ref.read(appConfigProvider).isE2e;

  @override
  Widget build(BuildContext context) {
    final isE2e = ref.watch(appConfigProvider).isE2e;
    final scanning = !_notFound;
    return AppScaffold(
      title: 'Scan barcode',
      e2eId: 'scaffold.barcode',
      actions: [
        if (scanning && !isE2e) _TorchButton(controller: _scanner),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: SnapGrubDesignTokens.space32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (scanning)
            ..._scannerView(context, isE2e)
          else
            ..._fallbackForm(
              context,
              isE2e,
            ),
          if (_error != null) ...[
            const SizedBox(height: SnapGrubDesignTokens.space16),
            InlineError(message: _error!),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Scanning
  // -------------------------------------------------------------------------

  List<Widget> _scannerView(BuildContext context, bool isE2e) {
    final theme = Theme.of(context);
    return [
      if (isE2e) ...[
        E2eId(
          id: 'barcode.e2e_unknown',
          child: OutlinedButton.icon(
            onPressed: _handling ? null : _useE2eUnknownBarcode,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('E2E unknown barcode'),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space12),
      ] else
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _CameraUnavailable(
                    onTypeCode: _typeCode,
                  ),
                ),
                IgnorePointer(child: _Reticle(active: _handling)),
                if (_handling)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: .45),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          const SizedBox(height: SnapGrubDesignTokens.space12),
                          Text(
                            'Looking up barcode…',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      if (isE2e && _handling) const LinearProgressIndicator(),
      const SizedBox(height: SnapGrubDesignTokens.space16),
      Semantics(
        liveRegion: true,
        child: Text(
          _handling
              ? 'Barcode found. Looking up…'
              : 'Center the barcode in the frame',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space4),
      Text(
        'Works with most packaged foods.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space8),
      Center(
        child: E2eId(
          id: 'barcode.type_code',
          child: TextButton.icon(
            onPressed: _handling ? null : _typeCode,
            icon: const Icon(Icons.keyboard_outlined),
            label: const Text('Enter barcode instead'),
          ),
        ),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // Not found → custom product
  // -------------------------------------------------------------------------

  List<Widget> _fallbackForm(BuildContext context, bool isE2e) {
    final theme = Theme.of(context);
    return [
      SgCard(
        color: context.sg.warning.withValues(alpha: .10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.search_off_rounded, color: context.sg.warning),
            const SizedBox(width: SnapGrubDesignTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product not found',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: SnapGrubDesignTokens.space4),
                  Text(
                    _notFoundReason ?? 'Add the details from the package.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_barcode != null) ...[
                    const SizedBox(height: SnapGrubDesignTokens.space8),
                    StatusPill(
                      label: _barcode!,
                      icon: Icons.qr_code_2_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space16),
      E2eId(
        id: 'barcode.use_label_ocr',
        child: FilledButton.tonalIcon(
          onPressed:
              _handling ? null : (isE2e ? _runE2eLabelOcr : _runLabelOcr),
          icon: _handling
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.document_scanner_outlined),
          label: const Text('Scan nutrition label'),
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space16),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SnapGrubDesignTokens.space12,
            ),
            child: Text(
              'or enter manually',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: SnapGrubDesignTokens.space16),
      E2eId(
        id: 'barcode.product_name',
        child: TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          decoration: InputDecoration(
            labelText: 'Product name',
            errorText: _nameError,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space8),
      Text(
        'Per serving',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space8),
      Row(
        children: [
          Expanded(
              child: _numberField(_caloriesController, 'Calories', 'kcal')),
          const SizedBox(width: SnapGrubDesignTokens.space8),
          Expanded(child: _numberField(_proteinController, 'Protein', 'g')),
        ],
      ),
      const SizedBox(height: SnapGrubDesignTokens.space12),
      Row(
        children: [
          Expanded(child: _numberField(_carbsController, 'Carbs', 'g')),
          const SizedBox(width: SnapGrubDesignTokens.space8),
          Expanded(
            child: _numberField(
              _fatController,
              'Fat',
              'g',
              action: TextInputAction.done,
            ),
          ),
        ],
      ),
      const SizedBox(height: SnapGrubDesignTokens.space16),
      E2eId(
        id: 'barcode.review_custom_product',
        child: FilledButton.icon(
          onPressed: _handling ? null : _openManualDraft,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Review product'),
        ),
      ),
      const SizedBox(height: SnapGrubDesignTokens.space4),
      Center(
        child: E2eId(
          id: 'barcode.scan_again',
          child: TextButton.icon(
            onPressed: _handling ? null : _resetScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan again'),
          ),
        ),
      ),
    ];
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String suffix, {
    TextInputAction action = TextInputAction.next,
  }) {
    return E2eId(
      id: 'barcode.${label.toLowerCase()}',
      child: TextField(
        controller: controller,
        textInputAction: action,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  void _useE2eUnknownBarcode() {
    setState(() {
      _barcode = '0000000000000';
      _notFound = true;
      _notFoundReason = 'E2E barcode was not found.';
      _error = null;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || _notFound) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    SgHaptics.detect();
    await _scanner.stop();
    await _lookup(raw);
  }

  Future<void> _typeCode() async {
    final code = await showSgSheet<String>(
      context: context,
      title: 'Enter barcode',
      subtitle: 'The numbers under the bars.',
      builder: (context) => const _TypeCodeForm(),
    );
    if (code == null || !mounted) return;
    if (!_isE2e) await _scanner.stop();
    await _lookup(code);
  }

  Future<void> _lookup(String code) async {
    setState(() {
      _handling = true;
      _barcode = code;
      _error = null;
    });
    try {
      final state = await ref.read(profileControllerProvider.future);
      final profile = state.profile;
      if (profile == null) throw StateError('Profile is not available.');
      final service = ref.read(multimodalRemoteServiceProvider);
      final response =
          await service.resolveBarcode(barcode: code, profile: profile);
      if (response.draft != null) {
        final draft =
            service.barcodeDraft(userId: profile.id, response: response);
        SgHaptics.logged();
        if (mounted) context.continueTo('/meal-editor', extra: draft);
        return;
      }
      if (!mounted) return;
      SgHaptics.warn();
      final reason = response.fallbackReason?.trim();
      setState(() {
        _notFound = true;
        // Server reasons are sentences; codes like `not_found` are not.
        _notFoundReason =
            reason != null && reason.contains(' ') ? reason : null;
      });
    } catch (error) {
      if (!mounted) return;
      SgHaptics.warn();
      setState(() {
        _notFound = true;
        _notFoundReason = null;
        _error =
            'Couldn’t look up this barcode. ${friendlyError(error).message}';
      });
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  Future<void> _runLabelOcr() async {
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;
      final ocrText = await recognizeLabelText(image.path);
      await _parseLabel(ocrText, productNameHint: _productNameHint());
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t read that label. ${friendlyError(error).message}');
      }
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  Future<void> _runE2eLabelOcr() async {
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      await _parseLabel(
        'E2E label 420 calories 24g protein',
        productNameHint: _productNameHint() ?? 'E2E label product',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t read that label. ${friendlyError(error).message}');
      }
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  Future<void> _parseLabel(String ocrText, {String? productNameHint}) async {
    final state = await ref.read(profileControllerProvider.future);
    final profile = state.profile;
    if (profile == null) throw StateError('Profile is not available.');
    final draft =
        await ref.read(multimodalRemoteServiceProvider).parseLabelText(
              userId: profile.id,
              profile: profile,
              ocrText: ocrText,
              barcode: _barcode,
              productNameHint: productNameHint,
            );
    SgHaptics.logged();
    if (mounted) context.continueTo('/meal-editor', extra: draft);
  }

  String? _productNameHint() {
    final name = _nameController.text.trim();
    return name.isEmpty ? null : name;
  }

  Future<void> _openManualDraft() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SgHaptics.warn();
      setState(() => _nameError = 'Enter a product name.');
      return;
    }
    final state = await ref.read(profileControllerProvider.future);
    final profile = state.profile;
    if (profile == null) {
      setState(() => _error = 'Your profile is still loading. Try again.');
      return;
    }
    final draft = MealDraft(
      userId: profile.id,
      timezone: profile.timezone,
      title: name,
      source: MealSource.barcode,
      provenanceType: 'barcode_manual',
      confidenceOverall: 0.4,
      analysisWarnings: const [
        'Product not in our database. Check nutrition before saving.'
      ],
      items: [
        MealDraftItem(
          name: name,
          quantity: 1,
          unit: 'serving',
          caloriesKcal: _number(_caloriesController.text),
          proteinG: _number(_proteinController.text),
          carbsG: _number(_carbsController.text),
          fatG: _number(_fatController.text),
          confidence: 0.4,
          sourceType: 'barcode_manual',
          sourceId: _barcode,
        ),
      ],
    );
    SgHaptics.tap();
    if (mounted) context.continueTo('/meal-editor', extra: draft);
  }

  void _resetScanner() {
    SgHaptics.tap();
    setState(() {
      _notFound = false;
      _notFoundReason = null;
      _barcode = null;
      _error = null;
      _nameError = null;
    });
    if (!_isE2e) _scanner.start();
  }

  double _number(String value) => double.tryParse(value.trim()) ?? 0;
}

/// Flash toggle; hidden when the camera has no torch.
class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (!state.isInitialized ||
            state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }
        final on = state.torchState == TorchState.on;
        return E2eId(
          id: 'barcode.torch',
          child: IconButton(
            tooltip: on ? 'Turn off flash' : 'Turn on flash',
            isSelected: on,
            onPressed: () {
              SgHaptics.tick();
              controller.toggleTorch();
            },
            icon: Icon(on ? Icons.flash_on_rounded : Icons.flash_off_rounded),
          ),
        );
      },
    );
  }
}

/// Corner-bracket framing guide over the camera preview.
class _Reticle extends StatelessWidget {
  const _Reticle({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.sg.success : Colors.white;
    return Center(
      child: FractionallySizedBox(
        widthFactor: .78,
        heightFactor: .42,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: SgMotion.of(context).settle,
          builder: (context, value, _) => CustomPaint(
            painter: _ReticlePainter(value ?? color),
          ),
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  _ReticlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 28.0;
    const r = 14.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    final corners = [
      Path()
        ..moveTo(0, arm)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(arm, 0),
      Path()
        ..moveTo(w - arm, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, arm),
      Path()
        ..moveTo(w, h - arm)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
        ..lineTo(w - arm, h),
      Path()
        ..moveTo(arm, h)
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
        ..lineTo(0, h - arm),
    ];
    for (final path in corners) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter old) => old.color != color;
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.onTypeCode});

  final VoidCallback onTypeCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(SnapGrubDesignTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            Text(
              'Camera unavailable',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: SnapGrubDesignTokens.space4),
            Text(
              'Allow camera access in Settings, or enter the barcode.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SnapGrubDesignTokens.space12),
            OutlinedButton(
              onPressed: onTypeCode,
              child: const Text('Enter barcode'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet body for typing a barcode. Pops with the digits.
class _TypeCodeForm extends StatefulWidget {
  const _TypeCodeForm();

  @override
  State<_TypeCodeForm> createState() => _TypeCodeFormState();
}

class _TypeCodeFormState extends State<_TypeCodeForm> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length < 6 || code.length > 14) {
      SgHaptics.warn();
      setState(() => _error = 'Enter 6–14 digits.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        E2eId(
          id: 'barcode.type_code.field',
          child: TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            maxLength: 14,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 1.5,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Barcode number',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: SnapGrubDesignTokens.space12),
        E2eId(
          id: 'barcode.type_code.submit',
          child: FilledButton(
            onPressed: _submit,
            child: const Text('Look up'),
          ),
        ),
      ],
    );
  }
}
