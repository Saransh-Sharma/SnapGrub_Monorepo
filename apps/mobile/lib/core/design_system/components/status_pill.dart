import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

enum StatusTone { neutral, positive, attention, info }

/// Small rounded status label. Pair with human copy from `labels.dart`;
/// never show raw enum names.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.icon,
    this.tone = StatusTone.neutral,
    super.key,
  });

  final String label;
  final IconData? icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.sg;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      StatusTone.neutral => scheme.onSurfaceVariant,
      StatusTone.positive => tokens.success,
      StatusTone.attention => tokens.warning,
      StatusTone.info => tokens.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
