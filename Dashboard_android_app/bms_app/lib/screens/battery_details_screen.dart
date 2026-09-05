import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class BatteryDetailsScreen extends StatelessWidget {
  const BatteryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pack Information
            SectionHeader(title: 'Pack Information'),
            const SizedBox(height: 14),
            BmsCard(
              child: Column(
                children: [
                  _PackInfoRow(
                      'Voltage', '48.6 V', Icons.electric_bolt,
                      AppTheme.electricBlue),
                  const Divider(height: 24),
                  _PackInfoRow(
                      'Current', '12.4 A', Icons.compress_rounded,
                      AppTheme.primaryGreen),
                  const Divider(height: 24),
                  _PackInfoRow(
                      'Power', '602 W', Icons.power_rounded,
                      AppTheme.warningOrange),
                  const Divider(height: 24),
                  _PackInfoRow(
                      'Temperature', '36.2 °C', Icons.thermostat_rounded,
                      AppTheme.criticalRed),
                  const Divider(height: 24),
                  _PackInfoRow(
                      'Capacity', '100 Ah', Icons.battery_full_rounded,
                      AppTheme.primaryGreen),
                  const Divider(height: 24),
                  _PackInfoRow(
                      'Cycle Count', '142', Icons.loop_rounded,
                      AppTheme.electricBlue),
                  const Divider(height: 24),
                  _PackInfoRow(
                      'Chemistry', 'LiFePO₄', Icons.science_outlined,
                      Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Individual Cell Monitoring
            SectionHeader(title: 'Individual Cell Monitoring'),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _CellCard(
                    number: 1, voltage: 3.21, temp: 35.1, status: 'Normal'),
                _CellCard(
                    number: 2, voltage: 3.18, temp: 36.8, status: 'Warning'),
                _CellCard(
                    number: 3, voltage: 3.22, temp: 37.2, status: 'Normal'),
                _CellCard(
                    number: 4, voltage: 3.20, temp: 35.9, status: 'Normal'),
              ],
            ),
            const SizedBox(height: 24),

            // Cell Balancing
            SectionHeader(title: 'Cell Balancing'),
            const SizedBox(height: 14),
            BmsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balancing Status',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Active',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const LabeledProgressBar(
                    label: 'Cell 1',
                    value: 0.82,
                    color: AppTheme.primaryGreen,
                    displayValue: '3.21 V',
                  ),
                  const SizedBox(height: 14),
                  const LabeledProgressBar(
                    label: 'Cell 2',
                    value: 0.78,
                    color: AppTheme.warningOrange,
                    displayValue: '3.18 V',
                  ),
                  const SizedBox(height: 14),
                  const LabeledProgressBar(
                    label: 'Cell 3',
                    value: 0.83,
                    color: AppTheme.primaryGreen,
                    displayValue: '3.22 V',
                  ),
                  const SizedBox(height: 14),
                  const LabeledProgressBar(
                    label: 'Cell 4',
                    value: 0.80,
                    color: AppTheme.primaryGreen,
                    displayValue: '3.20 V',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PackInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PackInfoRow(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _CellCard extends StatelessWidget {
  final int number;
  final double voltage;
  final double temp;
  final String status;

  const _CellCard({
    required this.number,
    required this.voltage,
    required this.temp,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case 'Warning':
        return AppTheme.warningOrange;
      case 'Critical':
        return AppTheme.criticalRed;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cell $number',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _statusColor.withOpacity(0.4), blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${voltage.toStringAsFixed(2)} V',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${temp.toStringAsFixed(1)}°C',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
