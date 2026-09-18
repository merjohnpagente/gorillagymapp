import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_theme.dart';
import '../services/attendance_service.dart';
import '../models/attendance.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  Attendance? _lastResult;
  String? _error;
  bool _torchOn = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() {
      _processing = true;
      _error = null;
      _lastResult = null;
    });
    _ctrl.stop();

    try {
      final att = await AttendanceService().recordFromQr(code);
      setState(() {
        _lastResult = att;
        _processing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _processing = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _lastResult = null;
      _error = null;
    });
    _ctrl.start();
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
                _torchOn ? Icons.flashlight_on : Icons.flashlight_off_outlined,
                color: _torchOn ? AppTheme.primary : AppTheme.textMuted),
            onPressed: () {
              _ctrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _ctrl,
                  onDetect: _onDetect,
                ),
                // Overlay frame
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Corner accents
                        ..._corners(),
                      ],
                    ),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
          ),

          // Result panel
          Expanded(
            flex: 2,
            child: _lastResult != null
                ? _buildSuccess()
                : _error != null
                    ? _buildError()
                    : _buildHint(),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 24.0;
    const thick = 3.0;
    const color = AppTheme.primary;
    return [
      Positioned(
          top: 0,
          left: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          top: 0,
          left: 0,
          child: Container(width: thick, height: size, color: color)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(width: thick, height: size, color: color)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: thick, height: size, color: color)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: thick, height: size, color: color)),
    ];
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner,
              color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          const Text('Point camera at member QR code',
              style: AppTheme.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('The attendance will be recorded automatically',
              style: AppTheme.bodyMuted.copyWith(fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final att = _lastResult!;
    final isCheckIn = att.timeOut == null;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.greenDim,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.check_circle, color: AppTheme.green, size: 36),
          ),
          const SizedBox(height: 16),
          Text(isCheckIn ? 'Checked In!' : 'Checked Out!',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(att.memberName,
              style: const TextStyle(
                  fontSize: 18,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              isCheckIn
                  ? 'Time in: ${_fmt(att.timeIn)}'
                  : 'Duration: ${att.durationStr}',
              style: AppTheme.bodyMuted),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Scan Next',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.redDim,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.error_outline, color: AppTheme.red, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Scan Failed',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: AppTheme.red, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgCardAlt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
