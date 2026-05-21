import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_safety_lamp_vault/providers/user_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _igniteController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       duration: const Duration(milliseconds: 2800),
       vsync: this,
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _igniteController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _igniteController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        ref.read(userProvider).setFirstTimeUser(false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _igniteController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    HapticFeedback.lightImpact();
    _igniteController.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_igniteController.status != AnimationStatus.completed) {
      if (_igniteController.value > 0.90) {
        _igniteController.forward();
      } else {
        _igniteController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // Subtle mine shaft grid background
          Positioned.fill(
            child: CustomPaint(painter: _ShaftGridPainter()),
          ),

          // Very faint warm radial glow from bottom
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1.2,
                  colors: [
                    kAccent.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Archive badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: kOutline, width: 1),
                      borderRadius: BorderRadius.circular(kRadiusPill),
                      color: kPanelBg,
                    ),
                    child: Text(
                      'SLV · ARCHIVE',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11.sp,
                        color: kAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'THE',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 5.0,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'SAFETY LAMP\nVAULT.',
                    style: GoogleFonts.playfairDisplay(
                      color: kPrimaryText,
                      fontSize: 46.sp,
                      fontWeight: FontWeight.w700,
                      height: 0.95,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: 48.w,
                    height: 1.5,
                    color: kAccent.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'A digital archive of underground history —\ncataloging the beacons of the pit.',
                    style: GoogleFonts.ibmPlexSans(
                      color: kSecondaryText,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w300,
                      height: 1.65,
                    ),
                  ),

                  const Spacer(),

                  // Hold-to-Ignite Interaction
                  Center(
                    child: Listener(
                      onPointerDown: _onPointerDown,
                      onPointerUp: _onPointerUp,
                      onPointerCancel: (_) => _onPointerUp(const PointerUpEvent()),
                      child: ScaleTransition(
                        scale: _pulseScale,
                        child: AnimatedBuilder(
                          animation: _igniteController,
                          builder: (context, child) {
                            final progress = _igniteController.value;
                            final flameColor = Color.lerp(
                              kSecondaryText,
                              kAccent,
                              progress,
                            )!;
                            return Container(
                              width: 220.w,
                              height: 220.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kPanelBg,
                                border: Border.all(
                                  color: Color.lerp(kOutline, kAccent, progress)!,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.lerp(
                                      Colors.transparent,
                                      kAccent.withValues(alpha: 0.35),
                                      progress,
                                    )!,
                                    blurRadius: 32 + (progress * 32),
                                    spreadRadius: progress * 12,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: Size(180.w, 180.w),
                                    painter: _GaugeCylinderPainter(
                                      progress: progress,
                                      flameColor: flameColor,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 48.h),
                                      Text(
                                        progress >= 0.99
                                            ? 'LAMP LIT'
                                            : 'HOLD TO IGNITE',
                                        style: GoogleFonts.ibmPlexMono(
                                          color: Color.lerp(kPrimaryText, kAccent, progress),
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: GoogleFonts.ibmPlexMono(
                                          color: Color.lerp(kSecondaryText, kAccent, progress),
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Footer
                  Center(
                    child: Text(
                      'Illuminating the archive — one lamp at a time.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        color: kSecondaryText.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mine shaft crosshatch grid background painter
class _ShaftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOutline.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShaftGridPainter old) => false;
}

/// Gauze cylinder motif painter — the central hold-to-ignite widget.
/// A minimal front-facing representation of a safety lamp's wire gauze cylinder:
/// a tall thin rectangle with a crosshatch grid inside, topped by a flame shape.
class _GaugeCylinderPainter extends CustomPainter {
  final double progress;
  final Color flameColor;

  _GaugeCylinderPainter({required this.progress, required this.flameColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Outer progress arc ───────────────────────────────────────────────────
    final trackPaint = Paint()
      ..color = kOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), size.width / 2, trackPaint);

    if (progress > 0) {
      final activePaint = Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: size.width / 2 - 2),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        activePaint,
      );
    }

    // ── Tick marks around outer ring ─────────────────────────────────────────
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const tickCount = 48;
    final r = size.width / 2;
    for (int i = 0; i < tickCount; i++) {
      final angle = ((i * 2 * math.pi) / tickCount) - (math.pi / 2);
      final isLong = i % 6 == 0;
      final isActive = (i / tickCount) <= progress;
      final innerR = r - (isActive ? (isLong ? 12 : 8) : (isLong ? 8 : 4));
      tickPaint.color = isActive ? kAccent : kOutline;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * innerR, cy + math.sin(angle) * innerR),
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
        tickPaint,
      );
    }

    // ── Gauze cylinder body ──────────────────────────────────────────────────
    final cylColor = Color.lerp(kOutline, kAccent.withValues(alpha: 0.7), progress)!;
    final cylPaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final cylW = size.width * 0.18;
    final cylTop = cy - size.height * 0.24;
    final cylBot = cy + size.height * 0.08;

    // Cylinder outline
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW, cylTop, cx + cylW, cylBot),
      cylPaint,
    );

    // Horizontal gauze lines (crosshatch)
    final hPaint = Paint()
      ..color = cylColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.7;
    final step = (cylBot - cylTop) / 8;
    for (int row = 1; row < 8; row++) {
      final y = cylTop + row * step;
      canvas.drawLine(Offset(cx - cylW, y), Offset(cx + cylW, y), hPaint);
    }
    // Vertical gauze lines
    final vStep = cylW * 2 / 5;
    for (int col = 1; col < 5; col++) {
      final x = cx - cylW + col * vStep;
      canvas.drawLine(Offset(x, cylTop), Offset(x, cylBot), hPaint);
    }

    // Fuel reservoir base
    final basePaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW * 1.3, cylBot, cx + cylW * 1.3, cylBot + size.height * 0.1),
      basePaint,
    );

    // ── Flame on top ─────────────────────────────────────────────────────────
    final flamePaint = Paint()
      ..color = flameColor.withValues(alpha: 0.85 + progress * 0.15)
      ..style = PaintingStyle.fill;

    final flamePath = Path();
    final flameBase = cylTop;
    final flameH = size.height * 0.14 * (0.5 + progress * 0.5);
    flamePath.moveTo(cx - cylW * 0.6, flameBase);
    flamePath.quadraticBezierTo(cx - cylW * 0.3, flameBase - flameH * 0.6,
        cx, flameBase - flameH);
    flamePath.quadraticBezierTo(cx + cylW * 0.3, flameBase - flameH * 0.6,
        cx + cylW * 0.6, flameBase);
    flamePath.close();
    canvas.drawPath(flamePath, flamePaint);

    // Bonnet hoop (top cap)
    final hoopPaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cx - cylW * 1.2, cylTop),
      Offset(cx + cylW * 1.2, cylTop),
      hoopPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugeCylinderPainter old) =>
      old.progress != progress || old.flameColor != flameColor;
}
