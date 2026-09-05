import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class BatteryHealthReportScreen extends StatelessWidget {
  const BatteryHealthReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Health Report'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.primaryGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF003D1F), Color(0xFF00162F)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Battery Score',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('94',
                                style: GoogleFonts.inter(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text('/100',
                                  style: GoogleFonts.inter(
                                      fontSize: 18,
                                      color:
                                          Colors.white.withOpacity(0.4))),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Excellent Condition',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen)),
                        ),
                        const SizedBox(height: 16),
                        Text('Generated: Aug 2, 2026',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4))),
                      ],
                    ),
                  ),
                  _ScoreGauge(score: 0.94),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Key Metrics
            SectionHeader(title: 'Key Metrics'),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: const [
                StatCard(
                    label: 'Estimated Life',
                    value: '18',
                    unit: 'months',
                    icon: Icons.schedule_rounded,
                    iconColor: AppTheme.electricBlue),
                StatCard(
                    label: 'Cycle Count',
                    value: '142',
                    unit: 'cycles',
                    icon: Icons.loop_rounded,
                    iconColor: AppTheme.primaryGreen),
                StatCard(
                    label: 'Capacity Loss',
                    value: '5.8',
                    unit: '%',
                    icon: Icons.trending_down_rounded,
                    iconColor: AppTheme.warningOrange),
                StatCard(
                    label: 'SOH',
                    value: '94.2',
                    unit: '%',
                    icon: Icons.health_and_safety_outlined,
                    iconColor: AppTheme.primaryGreen),
              ],
            ),
            const SizedBox(height: 20),

            // Health Breakdown
            SectionHeader(title: 'Health Breakdown'),
            const SizedBox(height: 14),
            BmsCard(
              child: Column(
                children: [
                  const LabeledProgressBar(
                    label: 'Capacity Retention',
                    value: 0.942,
                    color: AppTheme.primaryGreen,
                    displayValue: '94.2%',
                  ),
                  const SizedBox(height: 16),
                  const LabeledProgressBar(
                    label: 'Internal Resistance',
                    value: 0.88,
                    color: AppTheme.electricBlue,
                    displayValue: '88/100',
                  ),
                  const SizedBox(height: 16),
                  const LabeledProgressBar(
                    label: 'Cell Balance',
                    value: 0.91,
                    color: AppTheme.primaryGreen,
                    displayValue: '91%',
                  ),
                  const SizedBox(height: 16),
                  const LabeledProgressBar(
                    label: 'Thermal Health',
                    value: 0.96,
                    color: AppTheme.primaryGreen,
                    displayValue: '96%',
                  ),
                  const SizedBox(height: 16),
                  LabeledProgressBar(
                    label: 'Charge Acceptance',
                    value: 0.78,
                    color: AppTheme.warningOrange,
                    displayValue: '78%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recommendations
            SectionHeader(title: 'Recommendations'),
            const SizedBox(height: 14),
            ...[
              (Icons.check_circle_outline, 'Battery is in excellent condition.',
                  AppTheme.primaryGreen),
              (Icons.battery_charging_full_rounded,
                  'Keep charge between 20–80% to maximize lifespan.',
                  AppTheme.electricBlue),
              (Icons.thermostat_rounded,
                  'Avoid high-temperature environments above 45°C.',
                  AppTheme.warningOrange),
              (Icons.science_outlined,
                  'Next full diagnostic recommended in 3 months.',
                  Colors.purple),
            ].map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (item.$3).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: (item.$3).withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$1, color: item.$3, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item.$2,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimaryLight)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Generate PDF Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Generating PDF report...',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Generate PDF Report'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final double score;
  const _ScoreGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: CustomPaint(
        painter: _GaugePainter(score: score),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety_outlined,
                  color: AppTheme.primaryGreen, size: 28),
              Text('${(score * 100).toInt()}%',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  _GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * score,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [AppTheme.primaryGreen, Color(0xFF00E676)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
