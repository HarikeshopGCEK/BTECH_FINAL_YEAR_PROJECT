import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  int _filterIndex = 0;
  late TabController _tabCtrl;
  final filters = ['All', 'Critical', 'Warning', 'Info'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: filters.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _filterIndex = _tabCtrl.index);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon:
                    Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: AppTheme.primaryGreen),
            onPressed: () {},
            tooltip: 'Mark All Read',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          indicatorColor: AppTheme.primaryGreen,
          labelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: filters.map((f) => Tab(text: f)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AlertsList(filter: null),
          _AlertsList(filter: AlertSeverity.critical),
          _AlertsList(filter: AlertSeverity.warning),
          _AlertsList(filter: AlertSeverity.info),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.settings_rounded, color: Colors.white),
        label: Text('Alert Rules',
            style:
                GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  final AlertSeverity? filter;

  const _AlertsList({this.filter});

  List<Map<String, dynamic>> get _allAlerts => [
        {
          'title': 'High Temperature',
          'desc': 'Cell 3 temperature exceeded 45°C threshold',
          'time': 'Today, 02:14 PM',
          'severity': AlertSeverity.warning,
          'resolved': false,
        },
        {
          'title': 'Short Circuit Detected',
          'desc': 'Momentary short circuit on Pack A, auto-isolated',
          'time': 'Today, 11:32 AM',
          'severity': AlertSeverity.critical,
          'resolved': true,
        },
        {
          'title': 'Over Current',
          'desc': 'Current exceeded 20A limit. Load reduced automatically.',
          'time': 'Today, 09:18 AM',
          'severity': AlertSeverity.critical,
          'resolved': true,
        },
        {
          'title': 'Cell Imbalance',
          'desc': 'Voltage difference between cells > 50mV',
          'time': 'Yesterday, 08:45 PM',
          'severity': AlertSeverity.info,
          'resolved': true,
        },
        {
          'title': 'Battery Full',
          'desc': 'SOC reached 100%. Charging stopped automatically.',
          'time': 'Yesterday, 04:20 PM',
          'severity': AlertSeverity.success,
          'resolved': true,
        },
        {
          'title': 'Low Battery Warning',
          'desc': 'SOC dropped below 20%. Please connect charger.',
          'time': 'Yesterday, 10:05 AM',
          'severity': AlertSeverity.warning,
          'resolved': true,
        },
        {
          'title': 'Firmware Updated',
          'desc': 'BMS firmware v2.4.1 installed successfully',
          'time': '2 days ago',
          'severity': AlertSeverity.info,
          'resolved': true,
        },
        {
          'title': 'Thermal Spike',
          'desc': 'Pack temperature spiked to 48°C during fast charge',
          'time': '3 days ago',
          'severity': AlertSeverity.critical,
          'resolved': true,
        },
      ];

  List<Map<String, dynamic>> get _filtered {
    if (filter == null) return _allAlerts;
    return _allAlerts.where((a) => a['severity'] == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filtered;
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 56,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white24
                    : Colors.black26),
            const SizedBox(height: 16),
            Text('No alerts',
                style: GoogleFonts.inter(
                    fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: alerts.length,
      itemBuilder: (_, i) {
        final a = alerts[i];
        return AlertTile(
          title: a['title'],
          description: a['desc'],
          time: a['time'],
          severity: a['severity'],
          resolved: a['resolved'],
        );
      },
    );
  }
}
