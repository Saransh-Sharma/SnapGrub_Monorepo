import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapgrub/core/design_system/haptics.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

String formatNumber(double? value, {int decimals = 1}) {
  if (value == null) return '';
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(decimals);
}

/// The one numeric text field. Owns its controller (no leaks, no cursor
/// jumps on rebuild) and only resyncs when [value] changes from outside.
class SgNumberField extends StatefulWidget {
  const SgNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.nullable = false,
    this.decimal = true,
    this.helper,
    this.errorText,
    this.fieldKey,
    this.autofocus = false,
    this.textInputAction,
    super.key,
  });

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? suffix;
  final bool nullable;
  final bool decimal;
  final String? helper;
  final String? errorText;
  final Key? fieldKey;
  final bool autofocus;
  final TextInputAction? textInputAction;

  @override
  State<SgNumberField> createState() => _SgNumberFieldState();
}

class _SgNumberFieldState extends State<SgNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: formatNumber(widget.value));

  @override
  void didUpdateWidget(covariant SgNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = double.tryParse(_controller.text);
    if (widget.value != current &&
        !(widget.value == null && _controller.text.isEmpty)) {
      final text = formatNumber(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.suffix,
        helperText: widget.helper,
        errorText: widget.errorText,
      ),
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(widget.decimal ? r'[0-9.]' : r'[0-9]')),
      ],
      onChanged: (text) {
        if (widget.nullable && text.trim().isEmpty) {
          widget.onChanged(null);
          return;
        }
        widget.onChanged(double.tryParse(text) ?? 0);
      },
    );
  }
}

/// − value + stepper with haptic ticks and press-and-hold acceleration.
class SgStepper extends StatefulWidget {
  const SgStepper({
    required this.value,
    required this.onChanged,
    this.step = .25,
    this.min = 0,
    this.max = 9999,
    this.format,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String Function(double value)? format;
  final String? semanticLabel;

  @override
  State<SgStepper> createState() => _SgStepperState();
}

class _SgStepperState extends State<SgStepper> {
  Timer? _repeat;

  void _nudge(int direction) {
    final next = ((widget.value + widget.step * direction) / widget.step)
            .roundToDouble() *
        widget.step;
    final clamped = next.clamp(widget.min, widget.max).toDouble();
    if (clamped == widget.value) {
      SgHaptics.warn();
      _stop();
      return;
    }
    SgHaptics.tick();
    widget.onChanged(clamped);
  }

  void _startRepeat(int direction) {
    var interval = 260;
    void tick() {
      _nudge(direction);
      interval = math.max(60, (interval * .82).round());
      _repeat = Timer(Duration(milliseconds: interval), tick);
    }

    _repeat = Timer(const Duration(milliseconds: 380), tick);
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = widget.format?.call(widget.value) ??
        formatNumber(widget.value, decimals: 2);
    Widget button(IconData icon, int direction, String label) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: () => _nudge(direction),
            onLongPressStart: (_) => _startRepeat(direction),
            onLongPressEnd: (_) => _stop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20),
            ),
          ),
        );
    return Semantics(
      label: widget.semanticLabel,
      value: text,
      increasedValue: formatNumber(
          math.min(widget.max, widget.value + widget.step),
          decimals: 2),
      decreasedValue: formatNumber(
          math.max(widget.min, widget.value - widget.step),
          decimals: 2),
      onIncrease: () => _nudge(1),
      onDecrease: () => _nudge(-1),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(Icons.remove_rounded, -1, 'Less'),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: .85, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  text,
                  key: ValueKey(text),
                  textAlign: TextAlign.center,
                  style:
                      context.sg.metricSmall.copyWith(color: scheme.onSurface),
                ),
              ),
            ),
            button(Icons.add_rounded, 1, 'More'),
          ],
        ),
      ),
    );
  }
}

/// Vertical wheel picker (years, heights) with a haptic tick per item.
class SgWheelPicker<T> extends StatefulWidget {
  const SgWheelPicker({
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelFor,
    this.itemExtent = 48,
    this.height = 220,
    this.semanticLabel,
    super.key,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value) labelFor;
  final double itemExtent;
  final double height;
  final String? semanticLabel;

  @override
  State<SgWheelPicker<T>> createState() => _SgWheelPickerState<T>();
}

class _SgWheelPickerState<T> extends State<SgWheelPicker<T>> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(
    initialItem: math.max(0, widget.values.indexOf(widget.selected)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = widget.values.indexOf(widget.selected);
    return Semantics(
      label: widget.semanticLabel,
      value: widget.labelFor(widget.selected),
      increasedValue: index + 1 < widget.values.length
          ? widget.labelFor(widget.values[index + 1])
          : null,
      decreasedValue:
          index > 0 ? widget.labelFor(widget.values[index - 1]) : null,
      onIncrease: index + 1 < widget.values.length
          ? () => _controller.animateToItem(index + 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut)
          : null,
      onDecrease: index > 0
          ? () => _controller.animateToItem(index - 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut)
          : null,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: widget.itemExtent,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            ExcludeSemantics(
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: widget.itemExtent,
                diameterRatio: 1.6,
                perspective: .004,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) {
                  SgHaptics.tick();
                  widget.onChanged(widget.values[i]);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, i) {
                    final selected = i == index;
                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 140),
                        style: (selected
                                ? context.sg.metric
                                : theme.textTheme.titleLarge!)
                            .copyWith(
                          color: selected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(widget.labelFor(widget.values[i])),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal ruler for weights: minor tick every [step], a stronger haptic
/// on each whole unit. The big number above it rolls with the value.
class SgRulerPicker extends StatefulWidget {
  const SgRulerPicker({
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = .1,
    this.unit = 'kg',
    this.majorEvery = 10,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final String unit;

  /// Minor ticks between labelled major ticks.
  final int majorEvery;
  final String? semanticLabel;

  @override
  State<SgRulerPicker> createState() => _SgRulerPickerState();
}

class _SgRulerPickerState extends State<SgRulerPicker> {
  static const _tickGap = 12.0;
  late final ScrollController _controller =
      ScrollController(initialScrollOffset: _offsetFor(widget.value));
  late int _lastIndex = _indexFor(widget.value);

  int get _count => ((widget.max - widget.min) / widget.step).round() + 1;
  int _indexFor(double v) =>
      ((v - widget.min) / widget.step).round().clamp(0, _count - 1);
  double _offsetFor(double v) => _indexFor(v) * _tickGap;
  double _valueFor(int index) =>
      double.parse((widget.min + index * widget.step).toStringAsFixed(2));

  @override
  void didUpdateWidget(covariant SgRulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _indexFor(widget.value);
    if (index != _lastIndex &&
        _controller.hasClients &&
        !_controller.position.isScrollingNotifier.value) {
      _lastIndex = index;
      _controller.jumpTo(index * _tickGap);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final index =
          (_controller.offset / _tickGap).round().clamp(0, _count - 1);
      if (index != _lastIndex) {
        _lastIndex = index;
        if (index % widget.majorEvery == 0) {
          SgHaptics.tap();
        } else {
          SgHaptics.tick();
        }
        widget.onChanged(_valueFor(index));
      }
    }
    if (n is ScrollEndNotification) {
      final snapped = _lastIndex * _tickGap;
      if ((_controller.offset - snapped).abs() > .5) {
        Future.microtask(() => _controller.animateTo(snapped,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut));
      }
    }
    return false;
  }

  void _nudge(int d) {
    final index = (_indexFor(widget.value) + d).clamp(0, _count - 1);
    widget.onChanged(_valueFor(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final decimals = widget.step < 1 ? 1 : 0;
    final text = widget.value.toStringAsFixed(decimals);
    final index = _indexFor(widget.value);
    String labelAt(int i) =>
        '${_valueFor(i.clamp(0, _count - 1)).toStringAsFixed(decimals)} ${widget.unit}';
    return Semantics(
      label: widget.semanticLabel,
      value: '$text ${widget.unit}',
      increasedValue: labelAt(index + 1),
      decreasedValue: labelAt(index - 1),
      onIncrease: () => _nudge(1),
      onDecrease: () => _nudge(-1),
      child: Column(
        children: [
          ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(text, style: tokens.heroNumber),
                  const SizedBox(width: 6),
                  Text(widget.unit,
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ExcludeSemantics(
            child: SizedBox(
              height: 72,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pad = constraints.maxWidth / 2;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: _onScroll,
                        child: ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black,
                              Colors.black,
                              Colors.transparent
                            ],
                            stops: [0, .2, .8, 1],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            controller: _controller,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: pad),
                            itemExtent: _tickGap,
                            itemCount: _count,
                            itemBuilder: (context, i) {
                              final major = i % widget.majorEvery == 0;
                              final half = i % (widget.majorEvery ~/ 2) == 0;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: major ? 2 : 1.2,
                                    height: major
                                        ? 34
                                        : half
                                            ? 24
                                            : 16,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: major ? .7 : .3),
                                  ),
                                  if (major)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: SizedBox(
                                        height: 16,
                                        child: OverflowBox(
                                          maxWidth: 60,
                                          child: Text(
                                            _valueFor(i).toStringAsFixed(0),
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 4,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tokens.protein.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large numeric keypad for servings / quick-add, with haptic keys.
class SgKeypad extends StatelessWidget {
  const SgKeypad({
    required this.value,
    required this.onChanged,
    this.allowDecimal = true,
    this.maxLength = 6,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool allowDecimal;
  final int maxLength;

  void _press(String key) {
    SgHaptics.tick();
    if (key == '⌫') {
      if (value.isNotEmpty) onChanged(value.substring(0, value.length - 1));
      return;
    }
    if (key == '.' && (value.contains('.') || !allowDecimal)) return;
    if (value.length >= maxLength) return;
    onChanged(value == '0' && key != '.' ? key : '$value$key');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final key in keys)
          if (key == '.' && !allowDecimal)
            const SizedBox.shrink()
          else
            Semantics(
              button: true,
              label: key == '⌫'
                  ? 'Delete'
                  : key == '.'
                      ? 'Decimal point'
                      : key,
              excludeSemantics: true,
              child: Material(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _press(key),
                  child: Center(
                    child: key == '⌫'
                        ? const Icon(Icons.backspace_outlined)
                        : Text(key, style: context.sg.metric),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
