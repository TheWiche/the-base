import 'package:flutter/material.dart';

/// Wraps a child with a staggered fade + upward-slide entrance driven by the
/// given [animation].
///
/// Use together with a single [AnimationController] and per-item [Interval]s:
///
/// ```dart
/// final anim = CurvedAnimation(
///   parent: _controller,
///   curve: Interval(i * 0.08, i * 0.08 + 0.4, curve: Curves.easeOutCubic),
/// );
/// StaggerItem(animation: anim, child: MyWidget());
/// ```
class StaggerItem extends StatelessWidget {
  const StaggerItem({
    super.key,
    required this.animation,
    required this.child,
    this.beginOffset = const Offset(0, 0.28),
  });

  final Animation<double> animation;
  final Widget child;

  /// Starting slide offset. Defaults to 28 % down (slides upward on enter).
  final Offset beginOffset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Mixin that provides a single [AnimationController] to drive staggered
/// item entrances across an entire screen.
///
/// 1. Add `with SingleTickerProviderStateMixin, StaggerEntranceMixin` to your
///    State class (order matters — SingleTicker first).
/// 2. Call `initStagger(itemCount: n)` in `initState` **after** `super`.
/// 3. Wrap each item: `StaggerItem(animation: itemAnim(i), child: ...)`.
/// 4. Call `disposeStagger()` in `dispose` **before** `super`.
mixin StaggerEntranceMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController _staggerController;
  int _staggerCount = 8;

  static const int _itemMs  = 320;
  static const int _delayMs = 58;

  void initStagger({int itemCount = 8}) {
    _staggerCount = itemCount.clamp(1, 30);
    final totalMs = _itemMs + _delayMs * (_staggerCount - 1);
    _staggerController = AnimationController(
      duration: Duration(milliseconds: totalMs),
      vsync: this as TickerProvider,
    )..forward();
  }

  /// Returns an [Animation<double>] for the item at [index].
  Animation<double> itemAnim(int index) {
    final total = _staggerController.duration!.inMilliseconds.toDouble();
    final start = (index * _delayMs) / total;
    final end   = (index * _delayMs + _itemMs) / total;
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
  }

  void disposeStagger() => _staggerController.dispose();
}

/// Convenience: wraps a [ListView.builder] / [SliverList] item-builder to
/// auto-apply [StaggerItem] based on the item's index.
///
/// Compute per-item animations using [buildStaggerAnimations] once in
/// initState and pass the resulting list to [itemBuilder].
List<Animation<double>> buildStaggerAnimations({
  required AnimationController controller,
  required int itemCount,
  int itemDurationMs = 320,
  int itemDelayMs    = 58,
}) {
  final total = controller.duration!.inMilliseconds.toDouble();
  return List.generate(itemCount, (i) {
    final start = (i * itemDelayMs) / total;
    final end   = (i * itemDelayMs + itemDurationMs) / total;
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
  });
}

/// Creates an [AnimationController] appropriate for [itemCount] staggered items.
/// Remember to dispose it!
AnimationController createStaggerController({
  required TickerProvider vsync,
  required int itemCount,
  int itemDurationMs = 320,
  int itemDelayMs    = 58,
}) {
  final totalMs = itemDurationMs + itemDelayMs * (itemCount - 1).clamp(0, 999);
  return AnimationController(
    duration: Duration(milliseconds: totalMs),
    vsync: vsync,
  );
}
