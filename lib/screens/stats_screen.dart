import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_safety_lamp_vault/enum/my_enums.dart';
import 'package:the_safety_lamp_vault/models/project_model.dart';
import 'package:the_safety_lamp_vault/providers/project_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Ledger background painter ──────────────────────────────────────────────────
class _LedgerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pale = kOutline.withValues(alpha: 0.25);
    final thin = Paint()..color = pale..strokeWidth = 0.3;
    final thick = Paint()..color = pale..strokeWidth = 0.6;

    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), y % 48 == 0 ? thick : thin);
    }
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thin);
    }
    final accentLine = Paint()
      ..color = kAccent.withValues(alpha: 0.06)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), accentLine);
  }

  @override
  bool shouldRepaint(covariant _LedgerPainter old) => false;
}

// ── Health ring painter ────────────────────────────────────────────────────────
class _HealthRingPainter extends CustomPainter {
  final double value;
  final Color color;
  final String label;
  _HealthRingPainter({required this.value, required this.color, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    final bg = Paint()
      ..color = kOutline.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(cx, cy), r, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      value * math.pi * 2,
      false,
      fg,
    );

    final dot = Paint()..color = color..style = PaintingStyle.fill;
    final angle = -math.pi / 2 + value * math.pi * 2;
    canvas.drawCircle(Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r), 4, dot);

    final tp = Paint()..color = kPrimaryText;
    final sp = Paint()..color = kSecondaryText;
    _drawCentered(canvas, '${(value * 100).round()}%', cx, cy - 4, 28.sp, tp, 'ibmPlexMono');
    _drawCentered(canvas, label, cx, cy + 20, 9.sp, sp, 'ibmPlexSans');
  }

  void _drawCentered(Canvas canvas, String text, double cx, double cy, double size, Paint paint, String font) {
    final tf = GoogleFonts.getFont(font == 'ibmPlexMono' ? 'IBM Plex Mono' : 'IBM Plex Sans').copyWith(
      color: paint.color,
      fontSize: size,
      fontWeight: FontWeight.w700,
    );
    final para = TextPainter(text: TextSpan(text: text, style: tf), textDirection: TextDirection.ltr)
      ..layout();
    para.paint(canvas, Offset(cx - para.width / 2, cy - para.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter old) => old.value != value || old.color != color;
}

// ── Timeline node painter ─────────────────────────────────────────────────────
class _TimelineNodePainter extends CustomPainter {
  final bool active;
  final Color color;
  _TimelineNodePainter({required this.active, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.35;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color.withValues(alpha: active ? 0.2 : 0.08));
    canvas.drawCircle(Offset(cx, cy), r * 0.6, Paint()..color = color..style = PaintingStyle.fill);
    if (active) {
      canvas.drawCircle(Offset(cx, cy), r * 0.85, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineNodePainter old) => old.active != active || old.color != color;
}

// ── Main screen ────────────────────────────────────────────────────────────────
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _enterAnim;
  GasDetectionClass? _filterGas;
  int _ringStatIndex = 0;
  String? _selectedEra;
  int? _tappedStatIndex;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _enterAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  List<SafetyLampModel> _filtered(List<SafetyLampModel> all) {
    if (_filterGas == null) return all;
    return all.where((e) => e.gasDetectionClass == _filterGas).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(projectProvider).entries;
    final entries = _filtered(all);
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          CustomPaint(painter: _LedgerPainter(), size: Size.infinite),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildHeader(),
              if (entries.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 150.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFilterRow(all),
                      SizedBox(height: 24.h),
                      _buildRingAndStats(entries, all.length),
                      SizedBox(height: 28.h),
                      _buildEraTimeline(entries),
                      SizedBox(height: 28.h),
                      _buildInventoryGrid(entries),
                      SizedBox(height: 28.h),
                      _buildConditionBreakdown(entries),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverPadding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24.h, bottom: 8.h),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'VAULT LEDGER',
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _filterGas = null);
                    },
                    child: AnimatedOpacity(
                      opacity: _filterGas != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: kOutline),
                          borderRadius: BorderRadius.circular(kRadiusPill),
                        ),
                        child: Text(
                          'CLEAR FILTER',
                          style: GoogleFonts.ibmPlexMono(
                            color: kSecondaryText,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Inventory\nDashboard',
                style: GoogleFonts.playfairDisplay(
                  color: kPrimaryText,
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Interactive filter chips ─────────────────────────────────────────────────
  Widget _buildFilterRow(List<SafetyLampModel> all) {
    final gasClasses = all.map((e) => e.gasDetectionClass).toSet().toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    if (gasClasses.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 32.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gasClasses.length,
        separatorBuilder: (context, index) => SizedBox(width: 6.w),
        itemBuilder: (context, i) {
          final gc = gasClasses[i];
          final active = _filterGas == gc;
          final color = getGasDetectionColor(gc);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filterGas = active ? null : gc);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: active ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(kRadiusPill),
                border: Border.all(color: active ? color : kOutline, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.w, height: 6.w,
                    decoration: BoxDecoration(color: active ? kBackground : color, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    gc.label,
                    style: GoogleFonts.ibmPlexMono(
                      color: active ? kBackground : kPrimaryText,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Central health ring + mini stat cards ───────────────────────────────────
  Widget _buildRingAndStats(List<SafetyLampModel> entries, int totalAll) {
    final total = entries.length;
    final good = entries.where((e) =>
        e.preservationStatus == PreservationStatus.museumGrade ||
        e.preservationStatus == PreservationStatus.fullyOperational ||
        e.preservationStatus == PreservationStatus.serviceable).length;
    final health = total == 0 ? 0.0 : good / total;

    final ringLabels = ['VAULT HEALTH', 'TOTAL LAMPS', 'AT RISK'];
    final ringValues = [health, 1.0, total == 0 ? 0.0 : (total - good) / total];
    final ringColors = [health >= 0.7 ? const Color(0xFF22C55E) : health >= 0.4 ? kAccent : kSecondaryAccent, kAccent, kSecondaryAccent];

    final ringVal = ringValues[_ringStatIndex % ringValues.length];
    final ringCol = ringColors[_ringStatIndex % ringColors.length];
    final ringLbl = ringLabels[_ringStatIndex % ringLabels.length];

    final statItems = [
      _StatItem(total.toString(), 'LAMPS', kAccent),
      _StatItem(good.toString(), 'HEALTHY', const Color(0xFF22C55E)),
      _StatItem('${(health * 100).round()}%', 'SCORE', health >= 0.7 ? const Color(0xFF22C55E) : health >= 0.4 ? kAccent : kSecondaryAccent),
      _StatItem(_getEraSpan(entries), 'SPAN', kAccent),
    ];

    return AnimatedBuilder(
      animation: _enterAnim,
      builder: (context, _) {
        return Opacity(opacity: _enterAnim.value, child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _ringStatIndex++);
                  },
                  child: SizedBox(
                    width: 130.w,
                    height: 130.w,
                    child: CustomPaint(
                      painter: _HealthRingPainter(
                        value: ringVal * _enterAnim.value,
                        color: ringCol,
                        label: ringLbl,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    children: List.generate(statItems.length, (i) {
                      final item = statItems[i];
                      final tapped = _tappedStatIndex == i;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _tappedStatIndex = tapped ? null : i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: tapped ? 12.h : 10.h),
                          decoration: BoxDecoration(
                            color: tapped ? item.color.withValues(alpha: 0.08) : kPanelBg,
                            borderRadius: BorderRadius.circular(kRadiusSubtle),
                            border: Border.all(
                              color: tapped ? item.color.withValues(alpha: 0.4) : kOutline,
                              width: tapped ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item.value,
                                style: GoogleFonts.ibmPlexMono(
                                  color: item.color,
                                  fontSize: tapped ? 18.sp : 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                item.label,
                                style: GoogleFonts.ibmPlexMono(
                                  color: kSecondaryText,
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              AnimatedRotation(
                                turns: tapped ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 220),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14.sp,
                                  color: tapped ? item.color : kSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            if (_tappedStatIndex != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  _statDetail(statItems[_tappedStatIndex!].label, totalAll, entries),
                  style: GoogleFonts.ibmPlexSans(
                    color: kSecondaryText,
                    fontSize: 11.sp,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ));
      },
    );
  }

  String _statDetail(String label, int totalAll, List<SafetyLampModel> filtered) {
    switch (label) {
      case 'LAMPS':
        final filteredOut = totalAll - filtered.length;
        return filteredOut > 0
            ? 'Showing ${filtered.length} of $totalAll specimens ($filteredOut hidden by filter).'
            : '$totalAll specimens archived in this vault.';
      case 'HEALTHY':
        final pct = totalAll == 0 ? 0 : (filtered.where((e) =>
            e.preservationStatus == PreservationStatus.museumGrade ||
            e.preservationStatus == PreservationStatus.fullyOperational ||
            e.preservationStatus == PreservationStatus.serviceable).length / filtered.length * 100).round();
        return '$pct% of filtered specimens are in good or operational condition.';
      case 'SCORE':
        return 'Tap the ring to cycle between vault health, total count, and at-risk specimens.';
      case 'SPAN':
        return _getEraSpan(filtered);
      default:
        return '';
    }
  }

  // ── Era timeline ─────────────────────────────────────────────────────────────
  Widget _buildEraTimeline(List<SafetyLampModel> entries) {
    final yearCounts = <String, int>{};
    final regex = RegExp(r'\d{4}');
    for (final e in entries) {
      for (final m in regex.allMatches(e.eraOfProduction)) {
        final year = m.group(0)!;
        yearCounts[year] = (yearCounts[year] ?? 0) + 1;
      }
    }
    final sorted = yearCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (sorted.isEmpty) return const SizedBox.shrink();

    final maxCount = sorted.map((e) => e.value).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ERA DISTRIBUTION'),
        SizedBox(height: 16.h),
        SizedBox(
          height: 100.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (context, index) => SizedBox(width: 4.w),
            itemBuilder: (context, i) {
              final item = sorted[i];
              final frac = item.value / maxCount;
              final active = _selectedEra == item.key;
              final color = Color.lerp(kOutline, kAccent, frac)!;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedEra = active ? null : item.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 44.w,
                  padding: EdgeInsets.only(top: (1 - frac) * 60.h),
                  child: Column(
                    children: [
                      if (active)
                        Text(
                          '${item.value}',
                          style: GoogleFonts.ibmPlexMono(
                            color: kAccent,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const Spacer(),
                      CustomPaint(
                        size: Size(24.w, 24.w),
                        painter: _TimelineNodePainter(active: active, color: color),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.key,
                        style: GoogleFonts.ibmPlexMono(
                          color: active ? kAccent : kSecondaryText,
                          fontSize: 8.sp,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedEra != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              '${yearCounts[_selectedEra]} lamp${yearCounts[_selectedEra]! > 1 ? 's' : ''} from $_selectedEra.',
              style: GoogleFonts.ibmPlexSans(color: kSecondaryText, fontSize: 11.sp),
            ),
          ),
      ],
    );
  }

  // ── Inventory grid (body metal + apparatus) ─────────────────────────────────
  Widget _buildInventoryGrid(List<SafetyLampModel> entries) {
    final bodyCounts = <BodyMetal, int>{};
    final typeCounts = <ApparatusClassification, int>{};
    for (final e in entries) {
      bodyCounts[e.bodyMetal] = (bodyCounts[e.bodyMetal] ?? 0) + 1;
      typeCounts[e.apparatusClassification] = (typeCounts[e.apparatusClassification] ?? 0) + 1;
    }
    final bodySorted = bodyCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final typeSorted = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('MATERIAL INVENTORY'),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInventoryColumn('BODY METAL', bodySorted, (e) => getBodyMetalColor(e.key)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildInventoryColumn('TYPE', typeSorted, (e) => kAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryColumn<T>(
    String label,
    List<MapEntry<T, int>> sorted,
    Color Function(MapEntry<T, int>) getColor,
  ) {
    final maxVal = sorted.isEmpty ? 1 : sorted.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            color: kSecondaryText,
            fontSize: 7.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        ...sorted.take(5).map((item) {
          final color = getColor(item);
          final frac = item.value / maxVal;
          return Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.value} ${item.key}'),
                    duration: const Duration(milliseconds: 1200),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSubtle)),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: kPanelBg,
                  borderRadius: BorderRadius.circular(kRadiusSubtle),
                  border: Border.all(color: kOutline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6.w, height: 6.w,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        item.key.toString().split('.').last.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}'),
                        style: GoogleFonts.ibmPlexSans(color: kPrimaryText, fontSize: 10.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    SizedBox(
                      width: 40.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(kRadiusPill),
                        child: LinearProgressIndicator(
                          value: frac,
                          backgroundColor: kOutline.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 3.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${item.value}',
                      style: GoogleFonts.ibmPlexMono(
                        color: color,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Condition breakdown ──────────────────────────────────────────────────────
  Widget _buildConditionBreakdown(List<SafetyLampModel> entries) {
    final counts = <PreservationStatus, int>{};
    for (final e in entries) {
      counts[e.preservationStatus] = (counts[e.preservationStatus] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox.shrink();
    final total = entries.length;
    final barSegments = <_BarSegment>[];
    for (final item in sorted) {
      barSegments.add(_BarSegment(
        color: getConditionColor(item.key),
        fraction: item.value / total,
        label: item.key.label.split(' — ')[0],
        count: item.value,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CONDITION BREAKDOWN'),
        SizedBox(height: 16.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusPill),
          child: SizedBox(
            height: 12.h,
            child: Row(
              children: barSegments.map((s) {
                return Expanded(
                  flex: (s.fraction * 100).round().clamp(1, 100),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(s.count > 1 ? '${s.label}: ${s.count} lamps (${(s.fraction * 100).round()}%)' : '${s.label}: ${s.count} lamp (${(s.fraction * 100).round()}%)'),
                          duration: const Duration(milliseconds: 1200),
                          backgroundColor: kPanelBg,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSubtle)),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(color: s.color),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 4.h,
          children: barSegments.map((s) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${s.label}: ${s.count} (${(s.fraction * 100).round()}%)'),
                    duration: const Duration(milliseconds: 1200),
                    backgroundColor: kPanelBg,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSubtle)),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.w, height: 6.w,
                    decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${s.label} ${s.count}',
                    style: GoogleFonts.ibmPlexSans(color: kSecondaryText, fontSize: 9.sp),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3.w, height: 14.h, color: kAccent),
        SizedBox(width: 10.w),
        Text(
          title,
          style: GoogleFonts.ibmPlexMono(
            color: kPrimaryText,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  String _getEraSpan(List<SafetyLampModel> entries) {
    final years = <int>[];
    final regex = RegExp(r'\d{4}');
    for (final e in entries) {
      for (final m in regex.allMatches(e.eraOfProduction)) {
        final year = int.tryParse(m.group(0)!);
        if (year != null) years.add(year);
      }
    }
    if (years.isEmpty) return '—';
    years.sort();
    return years.first == years.last ? years.first.toString() : '${years.first}–${years.last}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, color: kSecondaryText.withValues(alpha: 0.3), size: 48.sp),
          SizedBox(height: 16.h),
          Text(
            _filterGas != null ? 'NO MATCHING LAMPS' : 'AWAITING LAMP DATA',
            style: GoogleFonts.ibmPlexMono(color: kSecondaryText, fontSize: 12.sp),
          ),
          if (_filterGas != null) ...[
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => setState(() => _filterGas = null),
              child: Text(
                'CLEAR FILTER',
                style: GoogleFonts.ibmPlexMono(color: kAccent, fontSize: 10.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────
class _StatItem {
  final String value;
  final String label;
  final Color color;
  _StatItem(this.value, this.label, this.color);
}

class _BarSegment {
  final Color color;
  final double fraction;
  final String label;
  final int count;
  _BarSegment({required this.color, required this.fraction, required this.label, required this.count});
}
