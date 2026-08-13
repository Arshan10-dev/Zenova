import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/permission_service.dart';
import '../home/main_shell.dart';
import '../permission/permission_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _opacity = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.86, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _proceed();
  }

  Future<void> _proceed() async {
    final results = await Future.wait([
      PermissionService.hasAudioPermission(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;

    final hasPermission = results[0] as bool;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => hasPermission ? const MainShell() : const PermissionScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: const Color(0xFF1A1A1D)),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      _EqBar(height: 18),
                      SizedBox(width: 7),
                      _EqBar(height: 34),
                      SizedBox(width: 7),
                      _EqBar(height: 24),
                      SizedBox(width: 7),
                      _EqBar(height: 42),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Cadence',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white.withValues(alpha: 0.95))),
              const SizedBox(height: 6),
              Text('Your music, offline.', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }
}

class _EqBar extends StatelessWidget {
  final double height;
  const _EqBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(color: AppColors.ember, borderRadius: BorderRadius.circular(4)),
    );
  }
}
