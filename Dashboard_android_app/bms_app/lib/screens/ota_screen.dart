import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class OTAScreen extends StatefulWidget {
  const OTAScreen({super.key});

  @override
  State<OTAScreen> createState() => _OTAScreenState();
}

class _OTAScreenState extends State<OTAScreen>
    with SingleTickerProviderStateMixin {
  _OTAState _state = _OTAState.idle;
  double _progress = 0;
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    setState(() => _state = _OTAState.checking);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _state = _OTAState.available);
  }

  Future<void> _download() async {
    setState(() {
      _state = _OTAState.downloading;
      _progress = 0;
    });
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (mounted) setState(() => _progress = i / 100);
    }
    if (mounted) setState(() => _state = _OTAState.installing);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _state = _OTAState.done);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTA Firmware Update'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current Firmware
            BmsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.memory_rounded,
                            color: AppTheme.electricBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Firmware',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight)),
                          Text('v2.4.1',
                              style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow2('Device', 'SmartBMS-001', isDark),
                  const SizedBox(height: 6),
                  _InfoRow2('Released', 'Jan 15, 2026', isDark),
                  _InfoRow2('Build', '#4812', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Latest Version
            if (_state != _OTAState.idle) ...[
              BmsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.new_releases_outlined,
                              color: AppTheme.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Latest Version',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight)),
                            Text('v2.5.0',
                                style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryGreen)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('New',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Release Notes',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 8),
                    ...[
                      '• Improved cell balancing algorithm',
                      '• Enhanced thermal management',
                      '• Edge AI model update v3.1',
                      '• Fixed BLE connectivity issues',
                      '• Reduced power consumption by 12%',
                    ].map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(note,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight)),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Progress
            if (_state == _OTAState.downloading ||
                _state == _OTAState.installing) ...[
              BmsCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        RotationTransition(
                          turns: _spinCtrl,
                          child: Icon(
                            _state == _OTAState.downloading
                                ? Icons.downloading_rounded
                                : Icons.settings_rounded,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _state == _OTAState.downloading
                              ? 'Downloading Firmware...'
                              : 'Installing...',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor),
                        ),
                        const Spacer(),
                        Text('${(_progress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _state == _OTAState.installing ? null : _progress,
                        minHeight: 10,
                        backgroundColor: isDark
                            ? const Color(0xFF2A2A3A)
                            : const Color(0xFFE8EBF0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Done State
            if (_state == _OTAState.done) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.primaryGreen, size: 56),
                    const SizedBox(height: 12),
                    Text('Update Complete!',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen)),
                    const SizedBox(height: 8),
                    Text('v2.5.0 installed successfully',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _buildButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (_state) {
      case _OTAState.idle:
        return ElevatedButton.icon(
          onPressed: _checkUpdate,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Check for Updates'),
        );
      case _OTAState.checking:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)),
          label: const Text('Checking...'),
        );
      case _OTAState.available:
        return ElevatedButton.icon(
          onPressed: _download,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download & Install'),
        );
      case _OTAState.downloading:
      case _OTAState.installing:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)),
          label: Text(_state == _OTAState.downloading
              ? 'Downloading...'
              : 'Installing...'),
        );
      case _OTAState.done:
        return ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Done'),
        );
    }
  }
}

class _InfoRow2 extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _InfoRow2(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label:  ',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight)),
        ],
      ),
    );
  }
}

enum _OTAState { idle, checking, available, downloading, installing, done }
