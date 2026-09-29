import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/router/nav.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/features/barcode/data/label_text_recognizer.dart';
import 'package:snapgrub/features/capture/application/capture_controller.dart';
import 'package:snapgrub/features/capture/data/capture_asset_repository.dart';
import 'package:snapgrub/features/capture/domain/capture_state.dart';
import 'package:snapgrub/features/conversation/application/conversation_controller.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/photo_analysis/application/analysis_queue_controller.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';
import 'package:url_launcher/url_launcher.dart';

enum CaptureMode {
  photo('Photo', Icons.restaurant_rounded),
  barcode('Barcode', Icons.qr_code_scanner_rounded),
  label('Label', Icons.document_scanner_rounded),
  describe('Describe', Icons.chat_bubble_outline_rounded);

  const CaptureMode(this.title, this.icon);
  final String title;
  final IconData icon;

  static CaptureMode fromName(String? name) => CaptureMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => CaptureMode.photo,
      );
}

/// Full-screen capture: Photo · Barcode · Label · Describe.
///
/// Photos are analyzed in the background: the shutter enqueues a job and
/// the photo flies back to Today, where a pending card shows live progress.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({this.initialMode = CaptureMode.photo, super.key});

  final CaptureMode initialMode;

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late CaptureMode _mode = widget.initialMode;
  late final PageController _modes =
      PageController(viewportFraction: .26, initialPage: _mode.index);
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  final _ripple = RippleController();
  MobileScannerController? _scanner;
  bool _torch = false;
  bool _busy = false;
  String? _busyLabel;
  String? _frozenPath;
  String? _heroTag;
  String? _error;
  bool _deniedOnce = false;
  late final CaptureController _capture =
      ref.read(captureControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _capture; // resolve eagerly while ref is valid
    WidgetsBinding.instance.addPostFrameCallback((_) => _activateMode(_mode));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _modes.dispose();
    _flash.dispose();
    _ripple.dispose();
    _scanner?.dispose();
    // ref is unusable once unmounted; use the notifier captured in initState.
    // Defer: providers must not change while the tree is unmounting.
    final capture = _capture;
    Future.microtask(capture.pausePreview);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final capture = ref.read(captureControllerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      if (_usesCamera(_mode)) unawaited(capture.initializeIfPermitted());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(capture.pausePreview());
    }
  }

  bool _usesCamera(CaptureMode mode) =>
      mode == CaptureMode.photo || mode == CaptureMode.label;

  Future<void> _activateMode(CaptureMode mode) async {
    final capture = ref.read(captureControllerProvider.notifier);
    if (mode == CaptureMode.barcode) {
      await capture.pausePreview();
      _scanner ??= MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      if (mounted) setState(() {});
      return;
    }
    if (_scanner != null) {
      final scanner = _scanner!;
      setState(() => _scanner = null);
      await scanner.dispose();
    }
    if (_usesCamera(mode)) {
      await capture.initializeIfPermitted();
      if (ref.read(captureControllerProvider).status ==
          CaptureStatus.permissionNeeded) {
        await _requestCamera();
      }
    } else {
      await capture.pausePreview();
    }
  }

  void _selectMode(CaptureMode mode) {
    if (mode == _mode) return;
    SgHaptics.tick();
    setState(() {
      _mode = mode;
      _error = null;
      _torch = false;
    });
    if (_modes.hasClients && _modes.page?.round() != mode.index) {
      _modes.animateToPage(
        mode.index,
        duration: SgMotion.of(context).settle,
        curve: Curves.easeOutCubic,
      );
    }
    _activateMode(mode);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<({String userId, DateTime day})?> _userDay() async {
    final user = await ref.read(homeUserContextProvider.future);
    if (user == null) return null;
    return (
      userId: user.userId,
      day: ref.read(userDayTickProvider(user.timezone))
    );
  }

  Future<void> _shutter() async {
    if (_busy) return;
    if (_mode == CaptureMode.label) return _captureLabel();
    final who = await _userDay();
    if (who == null) return;
    SgHaptics.shutter();
    _ripple.fire();
    _flash.forward(from: 0);
    setState(() => _busy = true);
    final asset = await ref
        .read(captureControllerProvider.notifier)
        .capture(userId: who.userId);
    if (!mounted) return;
    if (asset == null) {
      setState(() {
        _busy = false;
        _error = 'Photo didn’t save. Try again.';
      });
      return;
    }
    _sendToAnalysis(
        asset.localPath,
        () => ref
            .read(analysisQueueProvider.notifier)
            .enqueue(asset, day: who.day));
  }

  Future<void> _pickFromGallery() async {
    final who = await _userDay();
    if (who == null) return;
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final asset = await ref
          .read(captureAssetRepositoryProvider)
          .createFromCapture(userId: who.userId, file: file);
      if (!mounted) return;
      _sendToAnalysis(
          asset.localPath,
          () => ref
              .read(analysisQueueProvider.notifier)
              .enqueue(asset, day: who.day));
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = captureErrorMessage(error);
        });
      }
    }
  }

  /// Freezes the photo on screen inside a Hero, then pops so it flies into
  /// the pending card on Today.
  void _sendToAnalysis(String path, String Function() enqueue) {
    final jobId = enqueue();
    setState(() {
      _frozenPath = path;
      _heroTag = 'analysis-photo-$jobId';
    });
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) context.popOrGo('/home');
    });
  }

  Future<void> _captureLabel() async {
    final adapter = ref.read(cameraControllerAdapterProvider);
    SgHaptics.shutter();
    _flash.forward(from: 0);
    setState(() {
      _busy = true;
      _busyLabel = 'Reading label…';
      _error = null;
    });
    try {
      final file = await adapter.takePicture();
      if (!mounted) return;
      setState(() => _frozenPath = file.path);
      final text = await recognizeLabelText(file.path);
      final profile =
          (await ref.read(profileControllerProvider.future)).profile;
      if (profile == null) throw StateError('Profile is not available.');
      if (!mounted) return;
      setState(() => _busyLabel = 'Calculating nutrition…');
      final draft =
          await ref.read(multimodalRemoteServiceProvider).parseLabelText(
                userId: profile.id,
                profile: profile,
                ocrText: text,
              );
      SgHaptics.logged();
      if (mounted) context.continueTo('/meal-editor', extra: draft);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = null;
          _frozenPath = null;
          _error = captureErrorMessage(error);
        });
      }
    }
  }

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    SgHaptics.detect();
    await _resolveBarcode(raw);
  }

  Future<void> _resolveBarcode(String code) async {
    setState(() {
      _busy = true;
      _busyLabel = 'Looking up barcode…';
      _error = null;
    });
    await _scanner?.stop();
    try {
      final profile =
          (await ref.read(profileControllerProvider.future)).profile;
      if (profile == null) throw StateError('Profile is not available.');
      final service = ref.read(multimodalRemoteServiceProvider);
      final response =
          await service.resolveBarcode(barcode: code, profile: profile);
      if (!mounted) return;
      if (response.draft != null) {
        SgHaptics.logged();
        context.continueTo('/meal-editor',
            extra:
                service.barcodeDraft(userId: profile.id, response: response));
        return;
      }
      setState(() {
        _busy = false;
        _busyLabel = null;
      });
      await _showUnknownProduct(code, profile.id, profile.timezone);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _busyLabel = null;
        _error = friendlyError(error).message;
      });
      await _scanner?.start();
    }
  }

  Future<void> _showUnknownProduct(
      String code, String userId, String timezone) async {
    final choice = await showSgSheet<String>(
      context: context,
      title: 'Product not found',
      subtitle:
          'We don’t have this barcode yet. Scan the nutrition label instead.',
      builder: (context) => Column(
        children: [
          SgSheetAction(
            icon: Icons.document_scanner_rounded,
            label: 'Scan nutrition label',
            subtitle: 'Most accurate',
            onTap: () => Navigator.of(context).pop('label'),
          ),
          SgSheetAction(
            icon: Icons.edit_note_rounded,
            label: 'Enter manually',
            onTap: () => Navigator.of(context).pop('manual'),
          ),
          SgSheetAction(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan another barcode',
            onTap: () => Navigator.of(context).pop('again'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'label':
        _selectMode(CaptureMode.label);
      case 'manual':
        context.continueTo(
          '/meal-editor',
          extra: MealDraft(
            userId: userId,
            timezone: timezone,
            title: '',
            source: MealSource.barcode,
            provenanceType: 'barcode_manual',
            items: [
              MealDraftItem(
                name: '',
                quantity: 1,
                unit: 'serving',
                caloriesKcal: 0,
                proteinG: 0,
                carbsG: 0,
                fatG: 0,
                sourceType: 'barcode_manual',
                sourceId: code,
              ),
            ],
          ),
        );
      default:
        await _scanner?.start();
    }
  }

  Future<void> _typeBarcode() async {
    final controller = TextEditingController();
    final code = await showSgSheet<String>(
      context: context,
      title: 'Enter barcode',
      subtitle: 'The numbers under the bars.',
      builder: (context) => TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: context.sg.metric,
        decoration: const InputDecoration(hintText: '0 12345 67890 5'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Look up'),
        ),
      ),
    );
    controller.dispose();
    final cleaned = code?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (cleaned.isEmpty || !mounted) return;
    // Same rule as the barcode screen's validator.
    if (cleaned.length < 6 || cleaned.length > 14) {
      setState(() => _error = 'Enter 6–14 digits.');
      return;
    }
    await _resolveBarcode(cleaned);
  }

  Future<void> _toggleTorch() async {
    SgHaptics.tap();
    try {
      if (_mode == CaptureMode.barcode) {
        await _scanner?.toggleTorch();
      } else {
        final controller = ref.read(cameraControllerAdapterProvider).controller;
        await controller
            ?.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      }
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {}
  }

  Future<void> _sendDescription(String text) async {
    final who = await _userDay();
    if (who == null || text.trim().isEmpty) return;
    SgHaptics.tap();
    unawaited(ref
        .read(conversationControllerProvider.notifier)
        .sendMessage(who.day, text));
    if (mounted) context.popOrGo('/home');
  }

  /// Asks for camera access. [_deniedOnce] flips only after a real denial,
  /// so the first-ask copy shows until the person has actually said no.
  Future<void> _requestCamera() async {
    await ref.read(captureControllerProvider.notifier).requestPermission();
    if (!mounted) return;
    if (ref.read(captureControllerProvider).status ==
        CaptureStatus.permissionNeeded) {
      setState(() => _deniedOnce = true);
    }
  }

  Future<void> _openSettings() async {
    if (!kIsWeb && Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(captureControllerProvider);
    return E2eId(
      id: 'screen.capture',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Camera modes sit on black; Describe sits on the light aurora.
        value: _mode == CaptureMode.describe &&
                Theme.of(context).brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: Colors.black,
                ),
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                _viewfinder(capture),
                if (_mode != CaptureMode.describe) const _FramingGuide(),
                _topBar(),
                _bottomControls(),
                IgnorePointer(
                  child: FadeTransition(
                    opacity: Tween(begin: .85, end: 0.0).animate(
                      CurvedAnimation(parent: _flash, curve: Curves.easeOut),
                    ),
                    child: AnimatedBuilder(
                      animation: _flash,
                      builder: (context, child) =>
                          _flash.isAnimating ? child! : const SizedBox.shrink(),
                      child: const ColoredBox(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewfinder(CaptureState capture) {
    if (_frozenPath != null) {
      final image = Image.file(File(_frozenPath!), fit: BoxFit.cover);
      final framed = _heroTag == null
          ? ScanBeam(active: _busy, child: image)
          : Hero(tag: _heroTag!, child: image);
      return Stack(
        fit: StackFit.expand,
        children: [
          framed,
          if (_busyLabel != null) _BusyPill(label: _busyLabel!),
        ],
      );
    }
    if (_mode == CaptureMode.describe) {
      return _DescribePane(onSend: _sendDescription);
    }
    if (_mode == CaptureMode.barcode) {
      final scanner = _scanner;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (scanner != null)
            MobileScanner(controller: scanner, onDetect: _onBarcode),
          _BarcodeReticle(locked: _busy),
          if (_busyLabel != null) _BusyPill(label: _busyLabel!),
        ],
      );
    }
    switch (capture.status) {
      case CaptureStatus.cameraReady:
      case CaptureStatus.captureInProgress:
        final controller = ref.read(cameraControllerAdapterProvider).controller;
        if (controller == null || !controller.value.isInitialized) {
          return const _CameraLoading();
        }
        return SgRipple(
          controller: _ripple,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      case CaptureStatus.permissionNeeded:
        return _PermissionPane(
          denied: _deniedOnce,
          onAllow: _requestCamera,
          onSettings: _openSettings,
          onGallery: _pickFromGallery,
        );
      case CaptureStatus.featureDisabled:
        return _MessagePane(
          title: 'Camera logging is off',
          message: 'You can still type your meal or choose a photo.',
          onGallery: _pickFromGallery,
        );
      case CaptureStatus.error:
        return _MessagePane(
          title: 'Camera isn’t working',
          message: capture.message ?? 'Try again, or choose a photo.',
          onRetry: () =>
              ref.read(captureControllerProvider.notifier).initializePreview(),
          onGallery: _pickFromGallery,
        );
      case CaptureStatus.loading:
      case CaptureStatus.cameraPaused:
      case CaptureStatus.analysisInProgress:
        return const _CameraLoading();
    }
  }

  Widget _topBar() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _RoundGlassButton(
                icon: Icons.close_rounded,
                label: 'Close camera',
                onTap: () => context.popOrGo('/home'),
              ),
              const Spacer(),
              if (_mode != CaptureMode.describe)
                _RoundGlassButton(
                  icon: _torch
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                  label: _torch ? 'Turn off flash' : 'Turn on flash',
                  onTap: _toggleTorch,
                  active: _torch,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomControls() {
    // While typing a description the keyboard owns the bottom of the
    // screen; mode switching returns once it's dismissed.
    if (_mode == CaptureMode.describe &&
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final hint = switch (_mode) {
      CaptureMode.photo => 'Fit the whole plate in frame',
      CaptureMode.barcode => 'Center the barcode in the box',
      CaptureMode.label => 'Capture the Nutrition Facts panel',
      CaptureMode.describe => 'Describe your meal',
    };
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_mode != CaptureMode.describe || _error != null)
                AnimatedSwitcher(
                  duration: SgMotion.of(context).settle,
                  child: Text(
                    _error ?? hint,
                    key: ValueKey(_error ?? hint),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _error == null
                          ? Colors.white.withValues(alpha: .86)
                          : const Color(0xFFFFC7B3),
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (_mode != CaptureMode.describe)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundGlassButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Choose photo',
                      onTap: _busy ? null : _pickFromGallery,
                    ),
                    if (_mode == CaptureMode.barcode)
                      _RoundGlassButton(
                        icon: Icons.keyboard_rounded,
                        label: 'Enter barcode',
                        onTap: _busy ? null : _typeBarcode,
                        size: 78,
                      )
                    else
                      E2eId(
                        id: 'capture.shutter',
                        child: _Shutter(
                          busy: _busy,
                          onPressed: _shutter,
                          label: _mode == CaptureMode.label
                              ? 'Scan label'
                              : 'Take photo',
                        ),
                      ),
                    _RoundGlassButton(
                      icon: Icons.edit_note_rounded,
                      label: 'Enter manually',
                      onTap: _busy
                          ? null
                          : () => context.continueTo('/meal-editor'),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: PageView.builder(
                  controller: _modes,
                  itemCount: CaptureMode.values.length,
                  onPageChanged: (i) => _selectMode(CaptureMode.values[i]),
                  itemBuilder: (context, i) {
                    final mode = CaptureMode.values[i];
                    final selected = mode == _mode;
                    return Center(
                      child: E2eId(
                        id: 'capture.mode.${mode.name}',
                        child: Semantics(
                          selected: selected,
                          button: true,
                          label: '${mode.title} mode',
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () => _selectMode(mode),
                            child: AnimatedContainer(
                              duration: SgMotion.of(context).settle,
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.black.withValues(alpha: .25),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                mode.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: selected
                                          ? Colors.black
                                          : Colors.white.withValues(alpha: .8),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shutter extends StatefulWidget {
  const _Shutter({
    required this.busy,
    required this.onPressed,
    required this.label,
  });

  final bool busy;
  final VoidCallback onPressed;
  final String label;

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final motion = SgMotion.of(context);
    return Semantics(
      button: true,
      enabled: !widget.busy,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.busy ? null : widget.onPressed,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.busy ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _down ? .88 : 1,
          duration: _down ? motion.press : motion.settle,
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: SizedBox.square(
            dimension: 84,
            child: MetalSurface(
              metal: SgMetal.titanium,
              shape: MetalShape.ring,
              ringWidth: .16,
              idleGlint: true,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: AnimatedContainer(
                  duration: motion.settle,
                  decoration: BoxDecoration(
                    color: widget.busy
                        ? Colors.white.withValues(alpha: .4)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: widget.busy
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black54),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.size = 52,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap == null
              ? null
              : () {
                  SgHaptics.tap();
                  onTap!();
                },
          child: Opacity(
            opacity: onTap == null ? .4 : 1,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color:
                    active ? Colors.white : Colors.black.withValues(alpha: .35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .25)),
              ),
              child: Icon(icon,
                  color: active ? Colors.black : Colors.white,
                  size: size * .44),
            ),
          ),
        ),
      ),
    );
  }
}

/// Corner brackets that breathe while searching.
class _FramingGuide extends StatefulWidget {
  const _FramingGuide();

  @override
  State<_FramingGuide> createState() => _FramingGuideState();
}

class _FramingGuideState extends State<_FramingGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SgEffectsScope.of(context).animates) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final inset = 6 * Curves.easeInOut.transform(_c.value);
            final width = MediaQuery.sizeOf(context).width * .78;
            return SizedBox.square(
              dimension: width - inset * 2,
              child: CustomPaint(painter: _BracketPainter()),
            );
          },
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    const r = 18.0;
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height)
    ]) {
      final sx = corner.dx == 0 ? 1.0 : -1.0;
      final sy = corner.dy == 0 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(corner.dx, corner.dy + sy * len)
        ..lineTo(corner.dx, corner.dy + sy * r)
        ..quadraticBezierTo(corner.dx, corner.dy, corner.dx + sx * r, corner.dy)
        ..lineTo(corner.dx + sx * len, corner.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wide reticle with a sweeping laser; snaps tight when a code locks.
class _BarcodeReticle extends StatefulWidget {
  const _BarcodeReticle({required this.locked});

  final bool locked;

  @override
  State<_BarcodeReticle> createState() => _BarcodeReticleState();
}

class _BarcodeReticleState extends State<_BarcodeReticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SgEffectsScope.of(context).animates) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = SgMotion.of(context);
    final width = MediaQuery.sizeOf(context).width * .8;
    final accent = context.sg.protein.color;
    return IgnorePointer(
      child: Center(
        child: AnimatedContainer(
          duration: motion.settle,
          curve: motion.emphasized,
          width: widget.locked ? width * .72 : width,
          height: widget.locked ? 110 : 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.locked ? accent : Colors.white,
              width: widget.locked ? 4 : 3,
            ),
          ),
          child: widget.locked
              ? null
              : AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => Align(
                    alignment: Alignment(0, _c.value * 1.6 - .8),
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: accent,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: .8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _BusyPill extends StatelessWidget {
  const _BusyPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -.62),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox.square(
            dimension: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white54),
          ),
        ),
      );
}

class _PermissionPane extends StatelessWidget {
  const _PermissionPane({
    required this.denied,
    required this.onAllow,
    required this.onSettings,
    required this.onGallery,
  });

  final bool denied;
  final VoidCallback onAllow;
  final VoidCallback onSettings;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final ios = !kIsWeb && Platform.isIOS;
    return Theme(
      data: Theme.of(context),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: EmptyState(
            illustration: SgIllustrationKind.camera,
            title: 'Log meals with your camera',
            message: denied
                ? 'Camera access is off. Turn it on in Settings, or choose a photo.'
                : 'Only used when you tap the shutter. Photos stay private.',
            actionLabel: denied && ios ? 'Open Settings' : 'Allow camera',
            onAction: denied && ios ? onSettings : onAllow,
            secondaryLabel: 'Choose a photo',
            onSecondary: onGallery,
          ),
        ),
      ),
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.title,
    required this.message,
    required this.onGallery,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onGallery;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: EmptyState(
            illustration: SgIllustrationKind.camera,
            title: title,
            message: message,
            actionLabel: onRetry == null ? null : 'Try again',
            onAction: onRetry,
            secondaryLabel: 'Choose a photo',
            onSecondary: onGallery,
          ),
        ),
      );
}

/// Describe mode: type or dictate a meal; it goes to the chat on Today.
class _DescribePane extends StatefulWidget {
  const _DescribePane({required this.onSend});

  final ValueChanged<String> onSend;

  @override
  State<_DescribePane> createState() => _DescribePaneState();
}

class _DescribePaneState extends State<_DescribePane> {
  final _controller = TextEditingController();

  static const _examples = [
    'Two eggs, toast and a flat white',
    'Chicken biryani, a big plate',
    'Greek yogurt with honey and walnuts',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MeshAurora(
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(24, 88, 24,
              MediaQuery.viewInsetsOf(context).bottom > 0 ? 24 : 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What did you eat?', style: theme.textTheme.displaySmall),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Two eggs and toast…',
                ),
                onSubmitted: widget.onSend,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final example in _examples)
                    ActionChip(
                      label: Text(example),
                      onPressed: () {
                        SgHaptics.tick();
                        _controller.text = example;
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => FilledButton.icon(
                    onPressed: value.text.trim().isEmpty
                        ? null
                        : () => widget.onSend(value.text),
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: const Text('Log it'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
