import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedType = 0;
  final types = ['All', 'Charging', 'Discharging'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery History'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.download_outlined, color: textColor),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'csv',
                  child: Row(children: [
                    Icon(Icons.table_chart_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Export CSV')
                  ])),
              const PopupMenuItem(
                  value: 'pdf',
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Export PDF')
                  ])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                    child: _SummaryMini(
                        'Avg Temp', '34.8°C', Icons.thermostat_rounded,
                        AppTheme.criticalRed)),
                const SizedBox(width: 10),
                Expanded(
                    child: _SummaryMini('Energy', '42.1 kWh', Icons.bolt,
                        AppTheme.primaryGreen)),
                const SizedBox(width: 10),
                Expanded(
                    child: _SummaryMini('Sessions', '28', Icons.loop_rounded,
                        AppTheme.electricBlue)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: types.asMap().entries.map((e) {
                final selected = _selectedType == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = e.key),
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
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Text(e.value,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.grey)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Timeline List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _TimelineDay(
                  date: 'Today, Aug 2',
                  sessions: [
                    _SessionData(
                        type: 'Charging',
                        start: '08:00 AM',
                        end: '10:30 AM',
                        energy: '12.4 kWh',
                        tempAvg: '33.2°C',
                        startSoc: 22,
                        endSoc: 88),
                    _SessionData(
                        type: 'Discharging',
                        start: '11:00 AM',
                        end: '02:00 PM',
                        energy: '8.1 kWh',
                        tempAvg: '35.8°C',
                        startSoc: 88,
                        endSoc: 52),
                  ],
                ),
                _TimelineDay(
                  date: 'Yesterday, Aug 1',
                  sessions: [
                    _SessionData(
                        type: 'Charging',
                        start: '06:30 AM',
                        end: '09:00 AM',
                        energy: '11.8 kWh',
                        tempAvg: '32.5°C',
                        startSoc: 15,
                        endSoc: 100),
                    _SessionData(
                        type: 'Discharging',
                        start: '09:30 AM',
                        end: '05:00 PM',
                        energy: '18.2 kWh',
                        tempAvg: '38.4°C',
                        startSoc: 100,
                        endSoc: 18),
                    _SessionData(
                        type: 'Charging',
                        start: '07:00 PM',
                        end: '10:00 PM',
                        energy: '9.5 kWh',
                        tempAvg: '31.2°C',
                        startSoc: 18,
                        endSoc: 78),
                  ],
                ),
                _TimelineDay(
                  date: 'Jul 31',
                  sessions: [
                    _SessionData(
                        type: 'Discharging',
                        start: '08:00 AM',
                        end: '06:00 PM',
                        energy: '21.3 kWh',
                        tempAvg: '36.1°C',
                        startSoc: 95,
                        endSoc: 12),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryMini(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _SessionData {
  final String type;
  final String start;
  final String end;
  final String energy;
  final String tempAvg;
  final int startSoc;
  final int endSoc;

  _SessionData({
    required this.type,
    required this.start,
    required this.end,
    required this.energy,
    required this.tempAvg,
    required this.startSoc,
    required this.endSoc,
  });
}

class _TimelineDay extends StatelessWidget {
  final String date;
  final List<_SessionData> sessions;

  const _TimelineDay({required this.date, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ),
        ...sessions.map((s) => _SessionCard(session: s)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final _SessionData session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCharging = session.type == 'Charging';
    final color =
        isCharging ? AppTheme.primaryGreen : AppTheme.electricBlue;
    final icon = isCharging
        ? Icons.battery_charging_full_rounded
        : Icons.battery_3_bar_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      session.type,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      session.energy,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.start} – ${session.end}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ChipInfo('${session.startSoc}%→${session.endSoc}%',
                        Icons.battery_full_rounded, color),
                    const SizedBox(width: 8),
                    _ChipInfo(
                        session.tempAvg, Icons.thermostat_rounded, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _ChipInfo(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
