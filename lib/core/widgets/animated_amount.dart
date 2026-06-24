import 'package:flutter/material.dart';

import '../extensions/int_extensions.dart';

/// Animates a COP monetary integer from its previous value to [amount].
///
/// Uses [TweenAnimationBuilder] — no controller to dispose.
/// On first build the value runs from 0 to [amount].
/// On subsequent rebuilds it tweens from the previous value to the new one.
///
/// ```dart
/// AnimatedAmount(
///   amount: summary.availableBalance,
///   style: AppTextStyles.displayLarge.copyWith(color: balanceColor),
/// )
/// ```
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.amount,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve    = Curves.easeOutCubic,
    this.prefix   = '',
  });

  final int amount;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  /// Optional prefix rendered before the formatted amount (e.g. '+ ').
  final String prefix;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text('$prefix${amount.toCop}', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        return Text('$prefix${value.round().toCop}', style: style);
      },
    );
  }
}

/// A compact variant that shows a formatted amount with an optional label above.
class AnimatedAmountCard extends StatelessWidget {
  const AnimatedAmountCard({
    super.key,
    required this.label,
    required this.amount,
    required this.accentColor,
    this.amountStyle,
    this.labelStyle,
    this.prefix = '',
  });

  final String label;
  final int amount;
  final Color accentColor;
  final TextStyle? amountStyle;
  final TextStyle? labelStyle;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: labelStyle ??
              theme.textTheme.labelSmall?.copyWith(
                color: accentColor.withOpacity(0.8),
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 2),
        AnimatedAmount(
          amount: amount,
          style: amountStyle ??
              theme.textTheme.titleLarge!.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
          prefix: prefix,
        ),
      ],
    );
  }
}
