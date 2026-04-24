import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

/// Full-screen QR / barcode scanner with animated overlay.
/// Returns the raw scanned string via [onScanned] callback and pops.
class QrScannerScreen extends StatefulWidget {
  final void Function(String value) onScanned;
  final String title;
  final String subtitle;

  const QrScannerScreen({
    super.key,
    required this.onScanned,
    this.title = 'Scan Meter',
    this.subtitle = 'Point camera at QR or barcode on the water meter',
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _ctrl;
  late final AnimationController _lineCtrl;
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanned = true;

    // Brief success flash
    setState(() {});
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onScanned(raw);
        Navigator.pop(context);
      }
    });
  }

  void _toggleTorch() {
    _ctrl.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _switchCamera() => _ctrl.switchCamera();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutout = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed ─────────────────────────────────────────────────
          Positioned.fill(
            child: MobileScanner(controller: _ctrl, onDetect: _onDetect),
          ),

          // ── Dark overlay with transparent hole ──────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _OverlayPainter(
                cutoutSize: cutout,
                scanned: _scanned,
              ),
            ),
          ),

          // ── Animated scan line ──────────────────────────────────────────
          if (!_scanned)
            _buildScanLine(size, cutout),

          // ── Corner brackets ─────────────────────────────────────────────
          _buildCornerBrackets(size, cutout),

          // ── Top bar ─────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _torchOn ? Colors.amber : Colors.white,
                        ),
                        onPressed: _toggleTorch,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),

                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Success indicator
                  if (_scanned)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Meter detected!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ).animate().scale().fadeIn(),

                  // Switch camera
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BottomButton(
                          icon: Icons.flip_camera_android_rounded,
                          label: 'Flip',
                          onTap: _switchCamera,
                        ),
                        const SizedBox(width: 32),
                        _BottomButton(
                          icon: Icons.keyboard_rounded,
                          label: 'Manual',
                          onTap: () => _showManualEntry(context),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanLine(Size size, double cutout) {
    final topOffset = (size.height - cutout) / 2;
    return AnimatedBuilder(
      animation: _lineCtrl,
      builder: (_, __) {
        final y = topOffset + _lineCtrl.value * cutout;
        return Positioned(
          top: y - 1,
          left: (size.width - cutout) / 2 + 8,
          right: (size.width - cutout) / 2 + 8,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primaryLight.withOpacity(0.9),
                  Colors.white,
                  AppColors.primaryLight.withOpacity(0.9),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerBrackets(Size size, double cutout) {
    final l = (size.width - cutout) / 2;
    final t = (size.height - cutout) / 2;
    const c = 28.0; // corner arm length
    const w = 3.5;  // stroke width

    final color = _scanned ? AppColors.success : AppColors.primaryLight;

    return Positioned.fill(
      child: CustomPaint(
        painter: _CornerPainter(
          left: l, top: t, size: cutout,
          armLength: c, strokeWidth: w, color: color,
        ),
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter Meter Number',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Type the meter / consumer number manually',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Meter Number (e.g. MTR-001)',
                  prefixIcon: const Icon(Icons.speed_rounded),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final v = ctrl.text.trim();
                    if (v.isEmpty) return;
                    Navigator.pop(context);
                    widget.onScanned(v);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirm'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overlay painter ───────────────────────────────────────────────────────────
class _OverlayPainter extends CustomPainter {
  final double cutoutSize;
  final bool scanned;
  const _OverlayPainter({required this.cutoutSize, required this.scanned});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scanRect = Rect.fromCenter(
        center: Offset(cx, cy), width: cutoutSize, height: cutoutSize);

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));

    canvas.drawPath(
        path, Paint()..color = Colors.black.withOpacity(0.72));

    if (scanned) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
        Paint()
          ..color = AppColors.success.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.scanned != scanned || old.cutoutSize != cutoutSize;
}

// ── Corner painter ────────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final double left, top, size, armLength, strokeWidth;
  final Color color;
  const _CornerPainter({
    required this.left, required this.top, required this.size,
    required this.armLength, required this.strokeWidth, required this.color,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = left;
    final b = top;
    final re = left + size;
    final be = top + size;
    const cr = 10.0; // corner radius arm offset

    void drawCorner(double x, double y, double dx, double dy) {
      canvas.drawPath(
        Path()
          ..moveTo(x + dx * (armLength + cr), y)
          ..lineTo(x + dx * cr, y)
          ..quadraticBezierTo(x, y, x, y + dy * cr)
          ..lineTo(x, y + dy * (armLength + cr)),
        p,
      );
    }

    drawCorner(r, b, 1, 1);   // top-left
    drawCorner(re, b, -1, 1); // top-right
    drawCorner(r, be, 1, -1); // bottom-left
    drawCorner(re, be, -1, -1); // bottom-right
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ── Bottom icon button ────────────────────────────────────────────────────────
class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BottomButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
