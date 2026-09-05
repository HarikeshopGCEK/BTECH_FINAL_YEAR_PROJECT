import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPeriod = 0;
  int _selectedChart = 0;
  late TabController _tabController;

  final periods = ['Today', 'Week', 'Month', 'Year'];
  final charts = ['Voltage', 'Current', 'Temp', 'SOC', 'SOH', 'Power'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: charts.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: periods.asMap().entries.map((e) {
                final selected = _selectedPeriod == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryGreen
                              : (isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.1)),
                        ),
                      ),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark ? Colors.white : textColor),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Chart Type Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: charts.asMap().entries.map((e) {
                final selected = _selectedChart == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChart = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.electricBlue.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.electricBlue
                            : (isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.1)),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppTheme.electricBlue
                            : (isDark ? Colors.white70 : textColor),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Main Chart
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Chart Card
                  BmsCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getChartTitle(),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  _getChartSubtitle(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getChartColor().withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getCurrentValue(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _getChartColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: CustomPaint(
                            size: const Size(double.infinity, 180),
                            painter: _ChartPainter(
                              chartIndex: _selectedChart,
                              isDark: isDark,
                              color: _getChartColor(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _XAxisLabels(period: periods[_selectedPeriod]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Cards
                  SectionHeader(title: 'Summary'),
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
                          label: 'Energy Used',
                          value: '4.8',
                          unit: 'kWh',
                          icon: Icons.bolt,
                          iconColor: AppTheme.primaryGreen),
                      StatCard(
                          label: 'Avg Efficiency',
                          value: '96.2',
                          unit: '%',
                          icon: Icons.speed_rounded,
                          iconColor: AppTheme.electricBlue),
                      StatCard(
                          label: 'Peak Power',
                          value: '1.2',
                          unit: 'kW',
                          icon: Icons.flash_on,
                          iconColor: AppTheme.warningOrange),
                      StatCard(
                          label: 'Charge Cycles',
                          value: '3',
                          unit: 'today',
                          icon: Icons.loop,
                          iconColor: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getChartTitle() {
    const titles = [
      'Voltage vs Time',
      'Current vs Time',
      'Temperature vs Time',
      'SOC Trend',
      'SOH Trend',
      'Power Consumption'
    ];
    return titles[_selectedChart];
  }

  String _getChartSubtitle() {
    const subs = ['V', 'A', '°C', '%', '%', 'W'];
    return subs[_selectedChart];
  }

  String _getCurrentValue() {
    const vals = ['48.6 V', '12.4 A', '36.2 °C', '78%', '94.2%', '602 W'];
    return vals[_selectedChart];
  }

  Color _getChartColor() {
    const colors = [
      AppTheme.electricBlue,
      AppTheme.primaryGreen,
      AppTheme.criticalRed,
      AppTheme.primaryGreen,
      AppTheme.electricBlue,
      AppTheme.warningOrange,
    ];
    return colors[_selectedChart];
  }
}

class _XAxisLabels extends StatelessWidget {
  final String period;
  const _XAxisLabels({required this.period});

  List<String> get _labels {
    switch (period) {
      case 'Today':
        return ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM'];
      case 'Week':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Month':
        return ['W1', 'W2', 'W3', 'W4'];
      case 'Year':
        return ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _labels
          .map((l) => Text(l,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight)))
          .toList(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final int chartIndex;
  final bool isDark;
  final Color color;
  final _rng = Random(42);

  _ChartPainter({
    required this.chartIndex,
    required this.isDark,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Generate points
    final n = 24;
    final points = <Offset>[];
    double prev = 0.4 + _rng.nextDouble() * 0.2;
    for (int i = 0; i < n; i++) {
      prev += (_rng.nextDouble() - 0.48) * 0.08;
      prev = prev.clamp(0.1, 0.9);
      points.add(Offset(
        size.width * i / (n - 1),
        size.height * (1 - prev),
      ));
    }

    // Fill
    final fillPath = Path();
    fillPath.moveTo(points[0].dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final cp = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i - 1].dy,
      );
      linePath.quadraticBezierTo(cp.dx, cp.dy, points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dot at end
    canvas.drawCircle(
      points.last,
      5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      points.last,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.chartIndex != chartIndex || old.color != color;
}
