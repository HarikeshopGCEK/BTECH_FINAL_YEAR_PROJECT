import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_widgets.dart';
import 'battery_details_screen.dart';
import 'ai_prediction_screen.dart';
import 'analytics_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _rotateController;

  final List<Widget> _screens = const [
    _DashboardHome(),
    AnalyticsScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Home',
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0)),
                _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    selected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1)),
                _NavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Alerts',
                    selected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2)),
                _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryGreen : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Home Content ───────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning,',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.textSecondaryLight)),
                    Text('BMS Dashboard',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: textColor),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                      child: const Icon(Icons.person_outline,
                          color: AppTheme.primaryGreen, size: 20),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Large Battery Status Card
            _BatteryStatusCard(),
            const SizedBox(height: 20),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: const [
                StatCard(
                    label: 'Pack Voltage',
                    value: '48.6',
                    unit: 'V',
                    icon: Icons.electric_bolt,
                    iconColor: AppTheme.electricBlue),
                StatCard(
                    label: 'Current',
                    value: '12.4',
                    unit: 'A',
                    icon: Icons.compress_rounded,
                    iconColor: AppTheme.primaryGreen),
                StatCard(
                    label: 'Power',
                    value: '602',
                    unit: 'W',
                    icon: Icons.power_rounded,
                    iconColor: AppTheme.warningOrange),
                StatCard(
                    label: 'Temperature',
                    value: '36.2',
                    unit: '°C',
                    icon: Icons.thermostat_rounded,
                    iconColor: AppTheme.criticalRed),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions
            SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 14),
            _QuickActions(),
            const SizedBox(height: 20),

            // UPS & Charging Status
            Row(
              children: [
                Expanded(
                  child: BmsCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt,
                              color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Charging',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryLight)),
                            Text('Active',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BmsCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.electricBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.backup_outlined,
                              color: AppTheme.electricBlue),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UPS Status',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryLight)),
                            Text('Online',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.electricBlue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Alerts
            SectionHeader(
              title: 'Recent Alerts',
              action: 'See All',
              onActionTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen())),
            ),
            const SizedBox(height: 14),
            const AlertTile(
              title: 'High Temperature',
              description: 'Cell 3 temperature exceeded 45°C threshold',
              time: '2 minutes ago',
              severity: AlertSeverity.warning,
              resolved: false,
            ),
            const AlertTile(
              title: 'Cell Imbalance',
              description: 'Voltage difference between cells > 50mV',
              time: '1 hour ago',
              severity: AlertSeverity.info,
              resolved: true,
            ),
            const AlertTile(
              title: 'Battery Full',
              description: 'SOC reached 100%. Charging stopped.',
              time: '3 hours ago',
              severity: AlertSeverity.success,
              resolved: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Battery Status Card ─────────────────────────────────────────────────────
class _BatteryStatusCard extends StatefulWidget {
  @override
  State<_BatteryStatusCard> createState() => _BatteryStatusCardState();
}

class _BatteryStatusCardState extends State<_BatteryStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _progressAnim = Tween<double>(begin: 0, end: 0.78).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003D1F), Color(0xFF00611F), Color(0xFF001A40)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('Online',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Battery Health',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 4),
                    Text('Excellent',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen)),
                    const SizedBox(height: 20),
                    _InfoRow('SOC', '78%', Colors.white),
                    const SizedBox(height: 8),
                    _InfoRow('SOH', '94.2%', AppTheme.primaryGreen),
                    const SizedBox(height: 8),
                    _InfoRow('RUL', '18 months', AppTheme.electricBlue),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Circular Indicator
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => _CircularBattery(
                  progress: _progressAnim.value,
                  percentage: (78.0 * _progressAnim.value / 0.78).toInt(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label  ',
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white.withOpacity(0.5))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor)),
      ],
    );
  }
}

class _CircularBattery extends StatelessWidget {
  final double progress;
  final int percentage;

  const _CircularBattery({required this.progress, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(
        painter: _CircularPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'SOC',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularPainter extends CustomPainter {
  final double progress;
  _CircularPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [Color(0xFF00C853), Color(0xFF00E676), Color(0xFF2979FF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00C853).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularPainter old) => old.progress != progress;
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.battery_full_rounded, 'Battery\nDetails', AppTheme.electricBlue,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BatteryDetailsScreen()))),
      (Icons.psychology_outlined, 'AI\nAnalysis', AppTheme.primaryGreen,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AIPredictionScreen()))),
      (Icons.history_rounded, 'History', AppTheme.warningOrange, () {}),
      (Icons.settings_outlined, 'Settings', Colors.grey,
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions
          .map((a) => _QuickActionItem(
                icon: a.$1,
                label: a.$2,
                color: a.$3,
                onTap: a.$4,
              ))
          .toList(),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
