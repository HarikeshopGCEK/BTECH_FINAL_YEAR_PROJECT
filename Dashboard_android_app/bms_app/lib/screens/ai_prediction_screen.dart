import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  bool _analyzed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    Future.delayed(const Duration(milliseconds: 400), () {
      _animCtrl.forward();
      setState(() => _analyzed = true);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Prediction'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 14),
                const SizedBox(width: 4),
                Text('Edge AI',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen)),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0035), Color(0xFF00003A), Color(0xFF001A40)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Battery Health Score',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 6),
                        Text('94.2',
                            style: GoogleFonts.inter(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Text('/100',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.5))),
                        const SizedBox(height: 16),
                        _PredLabel('Confidence', '97.8%',
                            AppTheme.primaryGreen),
                        const SizedBox(height: 8),
                        _PredLabel(
                            'Predicted Life', '18 months', AppTheme.electricBlue),
                      ],
                    ),
                  ),
                  _AiScoreRing(score: 0.942),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Analysis Cards
            SectionHeader(title: 'Edge AI Analysis'),
            const SizedBox(height: 14),
            _AnalysisCard(
              icon: Icons.trending_down_rounded,
              title: 'Degradation Trend',
              value: 'Low',
              detail: '0.8% capacity loss per 100 cycles',
              color: AppTheme.primaryGreen,
              progress: 0.08,
            ),
            const SizedBox(height: 12),
            _AnalysisCard(
              icon: Icons.local_fire_department_outlined,
              title: 'Thermal Runaway Risk',
              value: 'Minimal',
              detail: 'All cells within safe temperature range',
              color: AppTheme.primaryGreen,
              progress: 0.05,
            ),
            const SizedBox(height: 12),
            _AnalysisCard(
              icon: Icons.warning_amber_rounded,
              title: 'Fault Prediction',
              value: 'Cell 2',
              detail: 'Early degradation detected in Cell 2',
              color: AppTheme.warningOrange,
              progress: 0.35,
            ),
            const SizedBox(height: 20),

            // Degradation Chart
            SectionHeader(title: 'Degradation Forecast'),
            const SizedBox(height: 14),
            BmsCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capacity over time',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: _DegradationChartPainter(isDark: isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Legend('Current', AppTheme.primaryGreen),
                      const SizedBox(width: 16),
                      _Legend('Predicted', AppTheme.electricBlue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recommendation Card
            SectionHeader(title: 'AI Recommendations'),
            const SizedBox(height: 14),
            _RecommendationCard(
              icon: Icons.check_circle_outline,
              text: 'Battery operating normally. No immediate action required.',
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 10),
            _RecommendationCard(
              icon: Icons.battery_charging_full_rounded,
              text: 'Recommended charging range: 20% – 80% for optimal longevity.',
              color: AppTheme.electricBlue,
            ),
            const SizedBox(height: 10),
            _RecommendationCard(
              icon: Icons.warning_amber_rounded,
              text: 'Cell 2 degradation detected. Monitor closely in next 2 weeks.',
              color: AppTheme.warningOrange,
            ),
            const SizedBox(height: 10),
            _RecommendationCard(
              icon: Icons.thermostat_rounded,
              text: 'Avoid ambient temperatures above 40°C to extend battery life.',
              color: AppTheme.criticalRed,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PredLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PredLabel(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label  ',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white.withOpacity(0.5))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _AiScoreRing extends StatelessWidget {
  final double score;
  const _AiScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _RingPainter(score: score),
        child: Center(
          child: Icon(Icons.auto_awesome,
              color: AppTheme.primaryGreen, size: 32),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  _RingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);
    final fgPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi * score, false, fgPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AnalysisCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final double progress;

  const _AnalysisCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight)),
                    Text(value,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ],
                ),
              ),
              Text('${(progress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? const Color(0xFF2A2A3A)
                  : const Color(0xFFE8EBF0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(detail,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _RecommendationCard(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 12,
        height: 4,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight)),
    ]);
  }
}

class _DegradationChartPainter extends CustomPainter {
  final bool isDark;
  _DegradationChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Current data (solid)
    final points = [
      Offset(0, size.height * 0.1),
      Offset(size.width * 0.2, size.height * 0.15),
      Offset(size.width * 0.4, size.height * 0.22),
      Offset(size.width * 0.6, size.height * 0.30),
      Offset(size.width * 0.7, size.height * 0.38),
    ];

    // Predicted (dashed)
    final predicted = [
      Offset(size.width * 0.7, size.height * 0.38),
      Offset(size.width * 0.8, size.height * 0.50),
      Offset(size.width * 0.9, size.height * 0.65),
      Offset(size.width, size.height * 0.78),
    ];

    final currentPath = Path();
    currentPath.moveTo(points[0].dx, points[0].dy);
    for (final p in points.skip(1)) {
      currentPath.lineTo(p.dx, p.dy);
    }

    // Fill under current
    final fillPath = Path.from(currentPath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.3),
            AppTheme.primaryGreen.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      currentPath,
      Paint()
        ..color = AppTheme.primaryGreen
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Predicted dashed line
    final dashPaint = Paint()
      ..color = AppTheme.electricBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < predicted.length - 1; i++) {
      final dx = predicted[i + 1].dx - predicted[i].dx;
      final dy = predicted[i + 1].dy - predicted[i].dy;
      final len = sqrt(dx * dx + dy * dy);
      final steps = (len / 10).floor();
      for (int j = 0; j < steps; j += 2) {
        canvas.drawLine(
          Offset(predicted[i].dx + dx * j / steps,
              predicted[i].dy + dy * j / steps),
          Offset(predicted[i].dx + dx * (j + 1) / steps,
              predicted[i].dy + dy * (j + 1) / steps),
          dashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
