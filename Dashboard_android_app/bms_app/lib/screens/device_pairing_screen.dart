import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  bool _connected = false;
  int? _connectingIndex;
  late AnimationController _scanCtrl;

  final _devices = [
    {'name': 'SmartBMS-001', 'mac': 'AA:BB:CC:11:22:33', 'rssi': -42, 'type': 'BMS v2'},
    {'name': 'SmartBMS-002', 'mac': 'AA:BB:CC:44:55:66', 'rssi': -61, 'type': 'BMS v2'},
    {'name': 'BMS-Lab-003', 'mac': 'DD:EE:FF:77:88:99', 'rssi': -78, 'type': 'BMS v1'},
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _connected = false;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connect(int index) async {
    setState(() => _connectingIndex = index);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _connectingIndex = null;
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Pairing'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // QR Scanner Card
            BmsCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.primaryGreen, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // QR grid
                        CustomPaint(
                          size: const Size(160, 160),
                          painter: _QRPainter(isDark: isDark),
                        ),
                        // Corner overlays
                        ...[ [0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0]].map(
                          (pos) => Positioned(
                            left: pos[0] == 0 ? 0 : null,
                            right: pos[0] == 1 ? 0 : null,
                            top: pos[1] == 0 ? 0 : null,
                            bottom: pos[1] == 1 ? 0 : null,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: pos[0] == 0
                                      ? const BorderSide(
                                          color: AppTheme.primaryGreen, width: 4)
                                      : BorderSide.none,
                                  right: pos[0] == 1
                                      ? const BorderSide(
                                          color: AppTheme.primaryGreen, width: 4)
                                      : BorderSide.none,
                                  top: pos[1] == 0
                                      ? const BorderSide(
                                          color: AppTheme.primaryGreen, width: 4)
                                      : BorderSide.none,
                                  bottom: pos[1] == 1
                                      ? const BorderSide(
                                          color: AppTheme.primaryGreen, width: 4)
                                      : BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Scan QR Code',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 4),
                  Text('Point camera at device QR label',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or scan nearby devices',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondaryLight)),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),

            // Scan Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _scanning ? null : _scan,
                icon: _scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.radar_rounded),
                label: Text(_scanning ? 'Scanning...' : 'Scan Nearby'),
              ),
            ),
            const SizedBox(height: 16),

            // Device List
            if (_devices.isNotEmpty) ...[
              SectionHeader(title: 'Nearby Devices'),
              const SizedBox(height: 12),
              ..._devices.asMap().entries.map((e) {
                final i = e.key;
                final device = e.value;
                final isConnecting = _connectingIndex == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: _connected && i == 0
                        ? Border.all(
                            color: AppTheme.primaryGreen, width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bluetooth_rounded,
                            color: AppTheme.electricBlue, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(device['name'] as String,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textColor)),
                              if (_connected && i == 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      shape: BoxShape.circle),
                                ),
                              ],
                            ]),
                            Text(
                              '${device['type']} • ${device['mac']} • ${device['rssi']} dBm',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: (_connected && i == 0) || isConnecting
                            ? null
                            : () => _connect(i),
                        child: isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryGreen))
                            : Text(
                                _connected && i == 0
                                    ? 'Connected'
                                    : 'Connect',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: _connected && i == 0
                                      ? AppTheme.primaryGreen
                                      : AppTheme.electricBlue,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _QRPainter extends CustomPainter {
  final bool isDark;
  _QRPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.15);
    final rng = Random(999);
    final cellSize = size.width / 10;
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        if (rng.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize + 1, r * cellSize + 1,
                cellSize - 2, cellSize - 2),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
