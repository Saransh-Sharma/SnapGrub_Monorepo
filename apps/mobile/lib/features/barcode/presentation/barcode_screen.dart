import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
    return AppScaffold(
      title: 'Barcode',
      child: ListView(
        children: [
          if (!_notFound) ...[
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
          ] else ...[
            Text('Barcode ${_barcode ?? ''}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Product name', border: OutlineInputBorder()),
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
            FilledButton.icon(
              onPressed: () => _openManualDraft(),
              icon: const Icon(Icons.edit),
              label: const Text('Review custom product'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _handling ? null : _runLabelOcr,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Use label OCR'),
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
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
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
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized =
          await recognizer.processImage(InputImage.fromFilePath(image.path));
      await recognizer.close();
      final state = await ref.read(profileControllerProvider.future);
      final profile = state.profile;
      if (profile == null) throw StateError('Profile is not available.');
      final draft =
          await ref.read(multimodalRemoteServiceProvider).parseLabelText(
                userId: profile.id,
                profile: profile,
                ocrText: recognized.text,
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
    setState(() {
      _notFound = false;
      _barcode = null;
      _error = null;
    });
    _scanner.start();
  }

  double _number(String value) => double.tryParse(value.trim()) ?? 0;
}
