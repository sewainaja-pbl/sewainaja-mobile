import 'package:flutter/material.dart';

/// Sebuah widget animasi fade-in & slide-up implicit yang sangat ringan.
/// Menggunakan [AnimatedOpacity] dan [AnimatedSlide] bawaan Flutter yang dioptimalkan di level engine.
/// Widget ini aman digunakan dalam Scroll View (List/Grid) karena tidak memicu relayout jank.
class SubtleFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;

  const SubtleFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.offset = const Offset(0.0, 0.08), // Default: slide up 8% dari tinggi widget
  });

  @override
  State<SubtleFadeIn> createState() => _SubtleFadeInState();
}

class _SubtleFadeInState extends State<SubtleFadeIn> {
  double _opacity = 0.0;
  late Offset _offset = widget.offset;

  @override
  void initState() {
    super.initState();

    if (widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _opacity = 1.0;
            _offset = Offset.zero;
          });
        }
      });
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            _opacity = 1.0;
            _offset = Offset.zero;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _offset,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
