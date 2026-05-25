import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapgrub/features/barcode/data/label_text_recognizer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/core/widgets/app_scaffold.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends ConsumerState<BarcodeScreen> {
  final _scanner = MobileScannerController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String? _barcode;
  String? _error;
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

  @override
  Widget build(BuildContext context) {
    final isE2e = ref.watch(appConfigProvider).isE2e;
    return AppScaffold(
      title: 'Barcode',
      child: ListView(
        children: [
          if (isE2e && !_notFound) ...[
            E2eId(
              id: 'barcode.e2e_unknown',
              child: OutlinedButton.icon(
                onPressed: _useE2eUnknownBarcode,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('E2E unknown barcode'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!_notFound && !isE2e) ...[
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_handling) const LinearProgressIndicator(),
          ] else if (!_notFound && isE2e) ...[
            if (_handling) const LinearProgressIndicator(),
          ] else ...[
            Text('Barcode ${_barcode ?? ''}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            E2eId(
              id: 'barcode.product_name',
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Product name', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _numberField(_caloriesController, 'Calories')),
                const SizedBox(width: 8),
                Expanded(child: _numberField(_proteinController, 'Protein')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _numberField(_carbsController, 'Carbs')),
                const SizedBox(width: 8),
                Expanded(child: _numberField(_fatController, 'Fat')),
              ],
            ),
            const SizedBox(height: 16),
            E2eId(
              id: 'barcode.review_custom_product',
              child: FilledButton.icon(
                onPressed: () => _openManualDraft(),
                icon: const Icon(Icons.edit),
                label: const Text('Review custom product'),
              ),
            ),
            const SizedBox(height: 8),
            E2eId(
              id: 'barcode.use_label_ocr',
              child: OutlinedButton.icon(
                onPressed:
                    _handling ? null : (isE2e ? _runE2eLabelOcr : _runLabelOcr),
                icon: const Icon(Icons.document_scanner),
                label: const Text('Use label OCR'),
              ),
            ),
            TextButton(
              onPressed: _resetScanner,
              child: const Text('Scan again'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return E2eId(
      id: 'barcode.${label.toLowerCase()}',
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  void _useE2eUnknownBarcode() {
    setState(() {
      _barcode = '0000000000000';
      _notFound = true;
      _error = 'E2E barcode was not found.';
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final values =
        capture.barcodes.map((barcode) => barcode.rawValue).whereType<String>();
    final raw = values.isEmpty ? null : values.first;
    if (raw == null || raw.isEmpty) return;
    setState(() {
      _handling = true;
      _barcode = raw;
      _error = null;
    });
    await _scanner.stop();
    try {
      final state = await ref.read(profileControllerProvider.future);
      final profile = state.profile;
      if (profile == null) throw StateError('Profile is not available.');
      final service = ref.read(multimodalRemoteServiceProvider);
      final response =
          await service.resolveBarcode(barcode: raw, profile: profile);
      if (response.draft != null) {
        final draft =
            service.barcodeDraft(userId: profile.id, response: response);
        if (mounted) context.go('/meal-editor', extra: draft);
        return;
      }
      if (mounted) {
        setState(() {
          _notFound = true;
          _error = response.fallbackReason;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _notFound = true;
          _error = error.toString();
        });
      }
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
      final state = await ref.read(profileControllerProvider.future);
      final profile = state.profile;
      if (profile == null) throw StateError('Profile is not available.');
      final draft =
          await ref.read(multimodalRemoteServiceProvider).parseLabelText(
                userId: profile.id,
                profile: profile,
                ocrText: ocrText,
                barcode: _barcode,
                productNameHint: _nameController.text.trim().isEmpty
                    ? null
                    : _nameController.text.trim(),
              );
      if (mounted) context.go('/meal-editor', extra: draft);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
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
      final state = await ref.read(profileControllerProvider.future);
      final profile = state.profile;
      if (profile == null) throw StateError('Profile is not available.');
      final draft =
          await ref.read(multimodalRemoteServiceProvider).parseLabelText(
                userId: profile.id,
                profile: profile,
                ocrText: 'E2E label 420 calories 24g protein',
                barcode: _barcode,
                productNameHint: _nameController.text.trim().isEmpty
                    ? 'E2E label product'
                    : _nameController.text.trim(),
              );
      if (mounted) context.go('/meal-editor', extra: draft);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  Future<void> _openManualDraft() async {
    final state = await ref.read(profileControllerProvider.future);
    final profile = state.profile;
    if (profile == null) {
      setState(() => _error = 'Profile is not available.');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Product name is required.');
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
        'Barcode was not found. Review custom product nutrition before saving.'
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
    if (mounted) context.go('/meal-editor', extra: draft);
  }

  void _resetScanner() {
    final isE2e = ref.read(appConfigProvider).isE2e;
    setState(() {
      _notFound = false;
      _barcode = null;
      _error = null;
    });
    if (!isE2e) _scanner.start();
  }

  double _number(String value) => double.tryParse(value.trim()) ?? 0;
}
