import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:snapgrub/core/design_system/motion.dart';

/// Odometer-style number: each digit rolls independently to its new value.
///
/// Uses tabular figures so columns never jitter. Screen readers get the whole
/// formatted value once.
class RollingNumber extends StatelessWidget {
  const RollingNumber({
    required this.value,
    required this.style,
    this.format,
    this.prefix = '',
    this.suffix = '',
    this.semanticsLabel,
    super.key,
  });

  final num value;
  final TextStyle style;
  final NumberFormat? format;
  final String prefix;
  final String suffix;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final text = '$prefix${(format ?? NumberFormat.decimalPattern()).format(value)}$suffix';
    final resolved = DefaultTextStyle.of(context).style.merge(style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: '0', style: resolved),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final digitSize = painter.size;
    painter.dispose();
    final motion = SgMotion.of(context);
    final chars = text.characters.toList();

    return Semantics(
      label: semanticsLabel == null ? text : '$semanticsLabel $text',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < chars.length; i++)
            _isDigit(chars[i])
                ? _DigitColumn(
                    // Keyed from the right so the units digit keeps its state
                    // when the number gains or loses a digit.
                    key: ValueKey('d${chars.length - i}'),
                    digit: int.parse(chars[i]),
                    size: digitSize,
                    style: resolved,
                    scaler: scaler,
                    duration: motion.of(Duration(milliseconds: 520 + 40 * (chars.length - i))),
                  )
                : Text(chars[i], style: resolved, textScaler: scaler),
        ],
      ),
    );
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

class _DigitColumn extends StatelessWidget {
  const _DigitColumn({
    required this.digit,
    required this.size,
    required this.style,
    required this.scaler,
    required this.duration,
    super.key,
  });

  final int digit;
  final Size size;
  final TextStyle style;
  final TextScaler scaler;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: digit.toDouble()),
      duration: duration,
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return SizedBox(
          width: size.width,
          height: size.height,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: size.height * 11,
              child: Transform.translate(
                offset: Offset(0, -value * size.height),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var d = 0; d <= 10; d++)
                      SizedBox(
                        height: size.height,
                        child: Text('${d % 10}',
                            style: style, textScaler: scaler),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
