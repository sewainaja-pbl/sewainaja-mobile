import 'package:flutter/material.dart';

/// Sebuah widget animasi fade-in implicit yang sangat ringan.
/// Menggunakan [AnimatedOpacity] bawaan Flutter yang dioptimalkan di level engine,
/// sehingga tidak memicu relayout (layout pass) pada widget anak saat berjalan,
/// menjadikannya aman untuk digunakan dalam Scroll View (List/Grid) tanpa membuat lag.
class SubtleFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SubtleFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<SubtleFadeIn> createState() => _SubtleFadeInState();
}

class _SubtleFadeInState extends State<SubtleFadeIn> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Jalankan fade-in setelah frame pertama selesai dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}
