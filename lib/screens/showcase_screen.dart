import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_safety_lamp_vault/enum/my_enums.dart';
import 'package:the_safety_lamp_vault/models/project_model.dart';
import 'package:the_safety_lamp_vault/providers/image_provider.dart';
import 'package:the_safety_lamp_vault/providers/project_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';

// ── Physics constants ─────────────────────────────────────────────────────────
const double kSwayMax = 0.65;    // max pendulum angle in radians
const double kSwayDamp = 0.94;   // angular damping per tick
const double kSwayK = 0.012;     // spring restore force
const double kGasMax = 1.0;      // max firedamp level (0–1)
const double kChainLen = 90.0;   // natural chain rest length

// ── Flame particle for animated glow ─────────────────────────────────────────
class _FlameParticle {
  double x, y, life, maxLife, vx, vy, size;
  _FlameParticle(this.x, this.y, this.life, this.maxLife, this.vx, this.vy, this.size);
}

// ── Lamp node — physics state for each lamp in the shaft ─────────────────────
class _LampNode {
  final SafetyLampModel model;
  final int index;
  final GasDetectionClass gasClass;
  final Offset anchor;   // top attachment point (fixed)
  double angle;          // current pendulum angle (radians)
  double angularVel;
  Offset pos;            // center of lamp disc
  bool dragging;
  bool focused;
  double? dragStartAngle;
  double? dragStartX;
  final List<_FlameParticle> flames;
  final double mass;
  double flickerPhase;

  _LampNode({
    required this.model,
    required this.index,
    required this.gasClass,
    required this.anchor,
  })  : angle = 0,
        angularVel = 0,
        pos = Offset(anchor.dx, anchor.dy + kChainLen),
        dragging = false,
        focused = false,
        dragStartAngle = null,
        dragStartX = null,
        flames = [],
        mass = _computeMass(gasClass),
        flickerPhase = math.Random().nextDouble() * math.pi * 2;

  double get radius => 26.0;

  static double _computeMass(GasDetectionClass gdc) {
    switch (gdc) {
      case GasDetectionClass.firedampDetection: return 1.4;
      case GasDetectionClass.blackdampIndicator: return 1.2;
      case GasDetectionClass.rescueService: return 1.6;
      case GasDetectionClass.inspectionLamp: return 1.0;
      case GasDetectionClass.generalIllumination: return 0.8;
    }
  }
}

class ShowcaseScreen extends ConsumerStatefulWidget {
  const ShowcaseScreen({super.key});
  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  List<_LampNode> _nodes = [];
  double _gasLevel = 0.0;       // 0 = clear air, 1 = full firedamp
  double _targetGas = 0.0;
  double _time = 0;
  int _lastHash = -1;
  bool _isBuilt = false;
  _LampNode? _focusedNode;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _rebuildNodes(List<SafetyLampModel> entries) {
    final hash = Object.hash(ref.read(projectProvider).stateVersion, entries.length);
    if (_isBuilt && _lastHash == hash) return;
    _isBuilt = true;
    _lastHash = hash;
    _nodes = [];
    if (entries.isEmpty) return;

    final viewSize = MediaQuery.of(context).size;
    final topSafe = MediaQuery.of(context).padding.top + 180.h;
    final bottomSafe = MediaQuery.of(context).padding.bottom + 120.h;
    final topAnchor = topSafe;
    final bottomAnchor = viewSize.height - bottomSafe - kChainLen - 26.0;
    final rand = math.Random(37);
    for (int i = 0; i < entries.length; i++) {
      final anchor = Offset(
        60.w + rand.nextDouble() * (viewSize.width - 120.w),
        topAnchor + rand.nextDouble() * (bottomAnchor - topAnchor),
      );
      final node = _LampNode(
        model: entries[i],
        index: i,
        gasClass: entries[i].gasDetectionClass,
        anchor: anchor,
      );
      node.angle = (rand.nextDouble() - 0.5) * 0.4;
      _nodes.add(node);
    }
  }

  void _onTick(Duration elapsed) {
    _time += 1 / 60;
    _gasLevel += (_targetGas - _gasLevel) * 0.04;

    final rand = math.Random();

    for (final node in _nodes) {
      if (node.focused) continue;

      if (!node.dragging) {
        // Pendulum physics: gravity restore + damping
        final restoreForce = -kSwayK * node.angle * node.mass;
        // Gas-induced drift: higher firedamp = more turbulence
        final turbulence = _gasLevel > 0.1
            ? (rand.nextDouble() - 0.5) * _gasLevel * 0.008
            : 0.0;
        node.angularVel += restoreForce + turbulence;
        node.angularVel *= kSwayDamp;
        node.angularVel = node.angularVel.clamp(-kSwayMax, kSwayMax);
        node.angle += node.angularVel;
        node.angle = node.angle.clamp(-kSwayMax, kSwayMax);
      }

      // Compute lamp position from pendulum angle
      node.pos = node.anchor + Offset(
        math.sin(node.angle) * kChainLen,
        math.cos(node.angle) * kChainLen,
      );

      // Flicker phase for flame animation
      node.flickerPhase += 0.08 + _gasLevel * 0.06;

      // Flame particles when gas level is elevated
      if (_gasLevel > 0.15 && rand.nextDouble() < 0.3) {
        node.flames.add(_FlameParticle(
          node.pos.dx + (rand.nextDouble() - 0.5) * 8,
          node.pos.dy - node.radius - 4,
          1.0,
          1.0,
          (rand.nextDouble() - 0.5) * 1.5,
          -0.8 - rand.nextDouble() * 1.5,
          1.5 + rand.nextDouble() * 2.5,
        ));
      }
      for (int i = node.flames.length - 1; i >= 0; i--) {
        final f = node.flames[i];
        f.x += f.vx;
        f.y += f.vy;
        f.life -= 0.04;
        if (f.life <= 0) node.flames.removeAt(i);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(projectProvider).entries;
    _rebuildNodes(entries);

    return Scaffold(
      backgroundColor: kBackground,
      body: entries.isEmpty ? _buildEmptyState() : _buildShaftView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'NO LAMPS IN THIS VAULT.',
        style: GoogleFonts.ibmPlexMono(
          color: kSecondaryText,
          fontSize: 11.sp,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildShaftView() {
    final viewSize = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Physics canvas (background + tethers + particles)
        RepaintBoundary(
          child: CustomPaint(
            size: viewSize,
            painter: _ShaftPainter(
              nodes: _nodes,
              gasLevel: _gasLevel,
              time: _time,
            ),
          ),
        ),
        // Gesture layer for swipe gas and defocus
        GestureDetector(
          onTap: () {
            if (_focusedNode != null) {
              setState(() {
                _focusedNode!.focused = false;
                _focusedNode = null;
              });
            }
          },
          onPanUpdate: (d) {
            // Drag DOWN increases gas level, UP decreases
            _targetGas = (_targetGas - d.delta.dy * 0.004).clamp(0, kGasMax);
          },
          child: Container(color: Colors.transparent),
        ),
        // Lamp node widgets (interactive)
        ..._nodes.map((n) => _buildNodeWidget(n)),
        // HUD
        _buildHUD(),
        // Focus panel overlay
        if (_focusedNode != null) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _focusedNode!.focused = false;
                _focusedNode = null;
              }),
              child: Container(color: kBackground.withValues(alpha: 0.65)),
            ),
          ),
          _buildFocusPanel(),
        ],
      ],
    );
  }

  Widget _buildNodeWidget(_LampNode node) {
    final hazard = isHazardLamp(node.model.preservationStatus, node.gasClass);
    final flameColor = hazard || _gasLevel > 0.5
        ? Color.lerp(kAccent, kSecondaryAccent, _gasLevel)!
        : Color.lerp(kSecondaryText, kAccent, 0.7 + math.sin(node.flickerPhase) * 0.3)!;

    return Positioned(
      left: node.pos.dx - node.radius + math.sin(node.flickerPhase * 1.3) * _gasLevel * 2,
      top: node.pos.dy - node.radius,
      child: GestureDetector(
        onPanStart: (d) => setState(() {
          node.dragging = true;
          node.dragStartAngle = node.angle;
          node.dragStartX = d.localPosition.dx;
          HapticFeedback.lightImpact();
        }),
        onPanUpdate: (d) {
          setState(() {
            final dx = d.localPosition.dx - (node.dragStartX ?? 0);
            node.angle = (node.dragStartAngle! + dx * 0.012).clamp(-kSwayMax, kSwayMax);
          });
        },
        onPanEnd: (_) => setState(() {
          node.dragging = false;
          node.dragStartAngle = null;
          node.dragStartX = null;
        }),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _focusedNode?.focused = false;
            _focusedNode = node;
            node.focused = true;
          });
        },
        child: SizedBox(
          width: node.radius * 2,
          height: node.radius * 2,
          child: CustomPaint(
            painter: _LampNodePainter(
              node: node,
              flameColor: flameColor,
              gasLevel: _gasLevel,
              time: _time,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    final pct = (_gasLevel * 100).round();
    final gasLabel = pct <= 3
        ? 'CLEAR AIR'
        : pct <= 25
            ? 'TRACE METHANE'
            : pct <= 55
                ? 'FIREDAMP PRESENT'
                : 'DANGER — HIGH FIREDAMP';
    final gasColor = pct <= 3
        ? kAccent
        : pct <= 25
            ? const Color(0xFFB8860B)
            : kSecondaryAccent;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16.h,
      left: 20.w,
      right: 20.w,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SHAFT ENVIRONMENT',
              style: GoogleFonts.ibmPlexMono(
                color: kAccent,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Lamp Constellation',
              style: GoogleFonts.playfairDisplay(
                color: kPrimaryText,
                fontSize: 30.sp,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: kPanelBg.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: gasColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.blur_on, size: 12.sp, color: gasColor),
                      SizedBox(width: 6.w),
                      Text(
                        'FIREDAMP',
                        style: GoogleFonts.ibmPlexMono(
                          color: gasColor,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 56.w,
                        height: 3.h,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(kRadiusPill),
                          child: LinearProgressIndicator(
                            value: _gasLevel,
                            backgroundColor: kOutline,
                            valueColor: AlwaysStoppedAnimation<Color>(gasColor),
                            minHeight: 3.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '$pct%',
                        style: GoogleFonts.ibmPlexMono(
                          color: gasColor,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: kPanelBg.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: kOutline),
                  ),
                  child: Text(
                    gasLabel,
                    style: GoogleFonts.ibmPlexMono(
                      color: gasColor,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: kPanelBg.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: kOutline),
                  ),
                  child: Text(
                    'DRAG UP TO RAISE GAS',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText.withValues(alpha: 0.5),
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusPanel() {
    final entry = _focusedNode!.model;
    final imgPath = ref.watch(imageProvider).getImagePath(entry.photoPath);
    final gdcColor = getGasDetectionColor(entry.gasDetectionClass);
    final hazard = isHazardLamp(entry.preservationStatus, entry.gasDetectionClass);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, val, child) => Transform.scale(
          scale: val.clamp(0.0, 1.0),
          child: Opacity(opacity: val.clamp(0.0, 1.0), child: child),
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusStandard),
            border: Border.all(
              color: hazard
                  ? kSecondaryAccent.withValues(alpha: 0.5)
                  : kAccent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (hazard ? kSecondaryAccent : kAccent).withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Panel header
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: (hazard ? kSecondaryAccent : kAccent).withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: () => setState(() {
                        _focusedNode?.focused = false;
                        _focusedNode = null;
                      }),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.sp,
                        color: kSecondaryText,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hazard
                                ? Icons.warning_amber_rounded
                                : Icons.local_fire_department_outlined,
                            size: 12.sp,
                            color: hazard ? kSecondaryAccent : kAccent,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'LAMP RECORD',
                            style: GoogleFonts.ibmPlexMono(
                              color: hazard ? kSecondaryAccent : kAccent,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 28.w),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(kRadiusSubtle),
                      child: SizedBox(
                        width: 80.w,
                        height: 80.w,
                        child: (imgPath != null && File(imgPath).existsSync())
                            ? Image.file(File(imgPath), fit: BoxFit.cover)
                            : Container(
                                color: kBackground,
                                child: CustomPaint(
                                  painter: _MiniGauzePainter(
                                    flameColor: hazard
                                        ? kSecondaryAccent.withValues(alpha: 0.6)
                                        : kAccent.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: gdcColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(kRadiusPill),
                                ),
                                child: Text(
                                  entry.gasDetectionClass.label.toUpperCase(),
                                  style: GoogleFonts.ibmPlexMono(
                                    color: gdcColor,
                                    fontSize: 7.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (entry.eraOfProduction.isNotEmpty) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: kAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(kRadiusPill),
                                  ),
                                  child: Text(
                                    entry.eraOfProduction,
                                    style: GoogleFonts.ibmPlexMono(
                                      color: kAccent,
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            entry.foundryOrManufacturer.isNotEmpty
                                ? entry.foundryOrManufacturer
                                : 'Unknown Maker',
                            style: GoogleFonts.playfairDisplay(
                              color: kPrimaryText,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            entry.vaultControlNumber,
                            style: GoogleFonts.ibmPlexMono(
                              color: kSecondaryText,
                              fontSize: 8.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Spec chips
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: kOutline),
                  ),
                ),
                child: Row(
                  children: [
                    _buildSpecChip('BODY', entry.bodyMetal.label),
                    SizedBox(width: 8.w),
                    _buildSpecChip('LOCK', entry.lockingMechanismType.label),
                    SizedBox(width: 8.w),
                    _buildSpecChip('FUEL', entry.fuelAndIlluminant),
                  ],
                ),
              ),
              // Open record button
              GestureDetector(
                onTap: () {
                  final idx = _focusedNode!.index;
                  setState(() {
                    _focusedNode!.focused = false;
                    _focusedNode = null;
                  });
                  Navigator.pushNamed(
                    context,
                    '/info_screen',
                    arguments: {'index': idx},
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(kRadiusStandard),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 14.sp, color: kBackground),
                      SizedBox(width: 6.w),
                      Text(
                        'OPEN FULL RECORD',
                        style: GoogleFonts.ibmPlexMono(
                          color: kBackground,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.sp,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          border: Border.all(color: kOutline),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText.withValues(alpha: 0.5),
                fontSize: 6.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.ibmPlexSans(
                color: kPrimaryText,
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main shaft background painter ─────────────────────────────────────────────
class _ShaftPainter extends CustomPainter {
  final List<_LampNode> nodes;
  final double gasLevel;
  final double time;

  _ShaftPainter({
    required this.nodes,
    required this.gasLevel,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGasHaze(canvas, size);
    _drawChains(canvas);
    _drawFlameParticles(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Dark pit background with very faint shaft timbers
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = kBackground,
    );

    // Fine crosshatch shaft grid
    final gridPaint = Paint()
      ..color = kOutline.withValues(alpha: 0.5)
      ..strokeWidth = 0.4;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Shaft wall seam lines (vertical heavy lines spaced as props)
    final seamPaint = Paint()
      ..color = kOutline.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;
    for (double x = 0; x < size.width; x += 108) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), seamPaint);
    }

    // Warm glow from lamps blending together at ground
    if (nodes.isNotEmpty) {
      for (final node in nodes) {
        final glowPaint = Paint()
          ..color = kAccent.withValues(alpha: 0.025)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
        canvas.drawCircle(node.pos, 80, glowPaint);
      }
    }
  }

  void _drawGasHaze(Canvas canvas, Size size) {
    if (gasLevel < 0.05) return;
    // Red firedamp haze rises from bottom
    final hazePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          kSecondaryAccent.withValues(alpha: gasLevel * 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      hazePaint,
    );

    // Wavy haze streaks
    if (gasLevel > 0.2) {
      final streakPaint = Paint()
        ..color = kSecondaryAccent.withValues(alpha: gasLevel * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      for (int layer = 0; layer < 3; layer++) {
        final path = Path();
        for (double x = -30; x < size.width + 30; x += 80 + layer * 30) {
          path.moveTo(x, size.height);
          for (double y = size.height; y > 0; y -= 8) {
            final wave = math.sin((x + y * 0.4 + time * 20 + layer * 120) * 0.018) * 12;
            path.lineTo(x + wave, y);
          }
        }
        canvas.drawPath(path, streakPaint);
      }
    }
  }

  void _drawChains(Canvas canvas) {
    // Draw chain links from anchor to lamp — dashed line with link segments
    for (final node in nodes) {
      if (node.focused) continue;
      final chainPaint = Paint()
        ..color = kSecondaryText.withValues(alpha: 0.35)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw short link segments along the chain
      const numLinks = 8;
      for (int i = 0; i < numLinks; i++) {
        final t1 = i / numLinks;
        final t2 = (i + 0.5) / numLinks;
        final p1 = Offset.lerp(node.anchor, node.pos, t1)!;
        final p2 = Offset.lerp(node.anchor, node.pos, t2)!;
        canvas.drawLine(p1, p2, chainPaint);
      }

      // Small circle at each link junction
      final dotPaint = Paint()
        ..color = kSecondaryText.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      for (int i = 1; i < numLinks; i++) {
        final t = i / numLinks;
        final p = Offset.lerp(node.anchor, node.pos, t)!;
        canvas.drawCircle(p, 1.5, dotPaint);
      }

      // Anchor hook at top
      final hookPaint = Paint()
        ..color = kSecondaryText.withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(node.anchor, 3, hookPaint);
    }
  }

  void _drawFlameParticles(Canvas canvas) {
    for (final node in nodes) {
      for (final f in node.flames) {
        final gasColor = Color.lerp(kAccent, kSecondaryAccent, node.model.gasDetectionClass == GasDetectionClass.firedampDetection ? 1.0 : 0.3)!;
        final paint = Paint()
          ..color = gasColor.withValues(alpha: f.life * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.size * 0.8);
        canvas.drawCircle(Offset(f.x, f.y), f.size * f.life, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShaftPainter old) => true;
}

// ── Individual lamp node painter ───────────────────────────────────────────────
class _LampNodePainter extends CustomPainter {
  final _LampNode node;
  final Color flameColor;
  final double gasLevel;
  final double time;

  _LampNodePainter({
    required this.node,
    required this.flameColor,
    required this.gasLevel,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = node.radius;

    // Outer warm glow when focused or gas elevated
    if (node.focused || gasLevel > 0.3) {
      final glowPaint = Paint()
        ..color = flameColor.withValues(alpha: node.focused ? 0.4 : gasLevel * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(Offset(cx, cy), r + 8, glowPaint);
    }

    // Main disc — dark with warm metallic shading
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [
          kPanelBg.withValues(alpha: 0.95),
          kBackground,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, basePaint);

    // Outer rim in carbide gold
    final rimPaint = Paint()
      ..color = flameColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(cx, cy), r, rimPaint);

    // Inner gauge ring
    final innerPaint = Paint()
      ..color = kOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, innerPaint);

    // Gauze crosshatch mini motif in center
    final gPaint = Paint()
      ..color = flameColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.7;
    final cyl = r * 0.32;
    final cylTop = cy - cyl;
    final cylBot = cy + cyl * 0.5;
    canvas.drawRect(
      Rect.fromLTRB(cx - cyl * 0.6, cylTop, cx + cyl * 0.6, cylBot),
      gPaint..style = PaintingStyle.stroke,
    );
    // Two horizontal gauze lines
    for (int row = 1; row < 3; row++) {
      final y = cylTop + row * (cylBot - cylTop) / 3;
      canvas.drawLine(Offset(cx - cyl * 0.6, y), Offset(cx + cyl * 0.6, y), gPaint);
    }

    // Flame on top — flickers with phase
    final flickerAmp = 0.5 + math.sin(node.flickerPhase) * 0.5;
    final flamePaint = Paint()
      ..color = flameColor.withValues(alpha: 0.8 + flickerAmp * 0.15)
      ..style = PaintingStyle.fill;
    final flameH = (r * 0.38) * (0.7 + flickerAmp * 0.5);
    final fPath = Path();
    fPath.moveTo(cx - cyl * 0.5, cylTop);
    fPath.quadraticBezierTo(
      cx + (math.sin(node.flickerPhase * 2) * cyl * 0.15),
      cylTop - flameH * 0.5,
      cx,
      cylTop - flameH,
    );
    fPath.quadraticBezierTo(
      cx + cyl * 0.15,
      cylTop - flameH * 0.4,
      cx + cyl * 0.5,
      cylTop,
    );
    fPath.close();
    canvas.drawPath(fPath, flamePaint);

    // Focus ring
    if (node.focused) {
      final focusPaint = Paint()
        ..color = kAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(cx, cy), r + 3, focusPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LampNodePainter old) => true;
}

// ── Mini gauze painter for focus panel thumbnail ──────────────────────────────
class _MiniGauzePainter extends CustomPainter {
  final Color flameColor;
  _MiniGauzePainter({required this.flameColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cylW = size.width * 0.22;
    final cylTop = size.height * 0.3;
    final cylBot = size.height * 0.72;

    final p = Paint()
      ..color = flameColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(Rect.fromLTRB(cx - cylW, cylTop, cx + cylW, cylBot), p);

    final hp = Paint()
      ..color = flameColor.withValues(alpha: 0.25)
      ..strokeWidth = 0.7;
    for (int r = 1; r < 5; r++) {
      final y = cylTop + r * (cylBot - cylTop) / 5;
      canvas.drawLine(Offset(cx - cylW, y), Offset(cx + cylW, y), hp);
    }
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW * 1.3, cylBot, cx + cylW * 1.3, cylBot + size.height * 0.12),
      p,
    );

    final fp = Paint()
      ..color = flameColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final fh = size.height * 0.15;
    final path = Path();
    path.moveTo(cx - cylW * 0.65, cylTop);
    path.quadraticBezierTo(cx, cylTop - fh, cx, cylTop - fh);
    path.quadraticBezierTo(cx, cylTop - fh, cx + cylW * 0.65, cylTop);
    path.close();
    canvas.drawPath(path, fp);
  }

  @override
  bool shouldRepaint(covariant _MiniGauzePainter old) =>
      old.flameColor != flameColor;
}
