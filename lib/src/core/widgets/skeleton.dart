import 'package:flutter/material.dart';

/// Wraps placeholder content and sweeps a soft highlight across it to signal
/// loading. Place [SkeletonBox]es inside and the shimmer animates over them all
/// with a single controller.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.06),
      base,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0 → 1
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (t * 2 - 0.5);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Slides a gradient horizontally by [dx] logical pixels.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);
  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// A neutral rounded placeholder block. Its colour is supplied by the enclosing
/// [Shimmer]'s shader, so any solid fill works here.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
