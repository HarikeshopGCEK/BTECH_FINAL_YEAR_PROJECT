import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _batteryController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _batteryFill;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _batteryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _batteryFill = Tween<double>(begin: 0, end: 0.78).animate(
      CurvedAnimation(parent: _batteryController, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _batteryController.forward();
    await Future.delayed(const Duration(milliseconds: 3200));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _batteryController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF0A1628), Color(0xFF001A0A)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Battery Icon
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: AnimatedBuilder(
                      animation: _batteryFill,
                      builder: (context, _) {
                        return _BatteryWidget(fillLevel: _batteryFill.value);
                      },
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Logo & Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SmartBMS',
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Edge AI Smart Battery\nManagement System',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Loading Dots
                  _LoadingDots(),
                  const SizedBox(height: 32),
                  Text(
                    'Initializing Edge AI Engine...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatteryWidget extends StatelessWidget {
  final double fillLevel;
  const _BatteryWidget({required this.fillLevel});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(140, 240),
      painter: _BatteryPainter(fillLevel: fillLevel),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double fillLevel;
  _BatteryPainter({required this.fillLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 30, size.width, size.height - 30),
      const Radius.circular(20),
    );

    // Terminal
    final terminalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, 34),
      const Radius.circular(8),
    );

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A2A1A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, bgPaint);
    canvas.drawRRect(terminalRect, bgPaint);

    // Fill
    final fillHeight = (size.height - 30 - 12) * fillLevel;
    final fillTop = size.height - 6 - fillHeight;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, fillTop, size.width - 12, fillHeight),
      const Radius.circular(14),
    );

    final color = fillLevel > 0.5
        ? const Color(0xFF00C853)
        : fillLevel > 0.2
            ? const Color(0xFFFF6D00)
            : const Color(0xFFD50000);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color, color.withOpacity(0.7)],
      ).createShader(fillRect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(fillRect, fillPaint);

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(fillRect, glowPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF00C853).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bodyRect, borderPaint);
    canvas.drawRRect(terminalRect, borderPaint);

    // Percentage text
    final pct = (fillLevel * 100).toInt();
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$pct%',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [Shadow(color: color, blurRadius: 12)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2 + 15,
      ),
    );

    // Bolt icon path
    if (fillLevel > 0.1) {
      final boltPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      final boltPath = Path();
      final cx = size.width / 2;
      final cy = size.height / 2 + 20;
      boltPath.moveTo(cx + 6, cy - 22);
      boltPath.lineTo(cx - 4, cy - 2);
      boltPath.lineTo(cx + 2, cy - 2);
      boltPath.lineTo(cx - 6, cy + 22);
      boltPath.lineTo(cx + 4, cy + 2);
      boltPath.lineTo(cx - 2, cy + 2);
      boltPath.close();
      canvas.drawPath(boltPath, boltPaint);
    }
  }

  @override
  bool shouldRepaint(_BatteryPainter old) => old.fillLevel != fillLevel;
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * sin(phase * pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.4 + 0.6 * scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
