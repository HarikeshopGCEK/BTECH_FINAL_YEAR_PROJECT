import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_widgets.dart';
import 'device_pairing_screen.dart';
import 'ota_screen.dart';
import 'battery_health_report_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon:
                    Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            BmsCard(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.electricBlue],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harikesh S',
                            style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textColor)),
                        Text('harikesh@gcek.ac.in',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Admin',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Connected Device
            _SectionLabel('Device'),
            _SettingsTile(
              icon: Icons.bluetooth_rounded,
              iconColor: AppTheme.electricBlue,
              title: 'Connected Device',
              subtitle: 'SmartBMS-001 • Connected',
              trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle)),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DevicePairingScreen())),
            ),
            _SettingsTile(
              icon: Icons.system_update_outlined,
              iconColor: AppTheme.warningOrange,
              title: 'OTA Firmware Update',
              subtitle: 'v2.4.1 — Check for updates',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OTAScreen())),
            ),
            _SettingsTile(
              icon: Icons.summarize_outlined,
              iconColor: AppTheme.electricBlue,
              title: 'Health Report',
              subtitle: 'Generate full battery report',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BatteryHealthReportScreen())),
            ),
            _SettingsTile(
              icon: Icons.history_rounded,
              iconColor: Colors.purple,
              title: 'Battery History',
              subtitle: 'View charge/discharge logs',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            const SizedBox(height: 8),

            // App Settings
            _SectionLabel('App'),
            BmsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ToggleTile(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    iconColor: isDark
                        ? Colors.amber
                        : const Color(0xFF4A4A6A),
                    title: 'Dark Mode',
                    value: isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                  const Divider(height: 1, indent: 60),
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppTheme.criticalRed,
                    title: 'Push Notifications',
                    value: true,
                    onChanged: (_) {},
                  ),
                  const Divider(height: 1, indent: 60),
                  _ToggleTile(
                    icon: Icons.sync_rounded,
                    iconColor: AppTheme.electricBlue,
                    title: 'Firebase Sync',
                    value: true,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Connectivity
            _SectionLabel('Connectivity'),
            _SettingsTile(
              icon: Icons.wifi_rounded,
              iconColor: AppTheme.electricBlue,
              title: 'Wi-Fi',
              subtitle: 'GCEK-Lab-5G',
            ),
            _SettingsTile(
              icon: Icons.bluetooth_rounded,
              iconColor: Colors.indigo,
              title: 'Bluetooth',
              subtitle: 'BT 5.0 — Active',
            ),

            // About
            _SectionLabel('About'),
            _SettingsTile(
              icon: Icons.language_rounded,
              iconColor: Colors.teal,
              title: 'Language',
              subtitle: 'English',
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              iconColor: Colors.grey,
              title: 'App Version',
              subtitle: 'v1.0.0 — Build 1',
            ),
            const SizedBox(height: 8),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.criticalRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded,
                    color: AppTheme.criticalRed),
                label: Text('Logout',
                    style: GoogleFonts.inter(
                        color: AppTheme.criticalRed,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppTheme.textSecondaryLight,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight)
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}
