import 'package:flutter/material.dart';

import '../extensions/int_extensions.dart';

/// Animates a COP monetary integer from its previous value to [amount].
///
/// On first render the value is shown immediately (no count-up).
/// Animation only plays when [amount] changes while the widget is mounted.
class AnimatedAmount extends StatefulWidget {
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
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount> {
  late double _begin;
  late double _end;

  @override
  void initState() {
    super.initState();
    // Skip animation on first render: both ends are the same value.
    _begin = widget.amount.toDouble();
    _end   = widget.amount.toDouble();
  }

  @override
  void didUpdateWidget(AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      // Real data change while screen is open → animate.
      setState(() {
        _begin = oldWidget.amount.toDouble();
        _end   = widget.amount.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // No tween needed: show value directly without animation.
    if (MediaQuery.of(context).disableAnimations || _begin == _end) {
      return Text('${widget.prefix}${widget.amount.toCop}', style: widget.style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _begin, end: _end),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, _) {
        return Text('${widget.prefix}${value.round().toCop}', style: widget.style);
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
