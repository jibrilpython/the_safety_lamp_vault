import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:the_safety_lamp_vault/models/project_model.dart';
import 'package:the_safety_lamp_vault/providers/image_provider.dart';
import 'package:the_safety_lamp_vault/providers/project_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class _ShaftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOutline.withValues(alpha: 0.6)
      ..strokeWidth = 0.4;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShaftGridPainter old) => false;
}

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});
  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  String? _alphaId;
  String? _betaId;

  void _showSelectionSheet(BuildContext context, bool isAlpha) {
    final entries = ref.read(projectProvider).entries;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(kRadiusLarge)),
          border: const Border(top: BorderSide(color: kOutline, width: 1)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: kOutline,
                    borderRadius: BorderRadius.circular(kRadiusPill))),
            SizedBox(height: 24.h),
            Text(
              'SELECT ${isAlpha ? 'ALPHA' : 'BETA'} SPECIMEN',
              style: GoogleFonts.ibmPlexMono(
                color: kPrimaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'NO LAMPS IN VAULT',
                        style: GoogleFonts.ibmPlexMono(
                            color: kSecondaryText, fontSize: 11.sp),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) {
                        final e = entries[i];
                        final isDisabled = (isAlpha && _betaId == e.id) ||
                            (!isAlpha && _alphaId == e.id);
                        return GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () {
                                  setState(() {
                                    if (isAlpha) {
                                      _alphaId = e.id;
                                    } else {
                                      _betaId = e.id;
                                    }
                                  });
                                  Navigator.pop(ctx);
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: EdgeInsets.only(bottom: 10.h),
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color:
                                  isDisabled ? Colors.transparent : kBackground,
                              borderRadius:
                                  BorderRadius.circular(kRadiusStandard),
                              border: Border.all(
                                color: (_alphaId == e.id || _betaId == e.id)
                                    ? kAccent
                                    : kOutline,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department_outlined,
                                  color: isDisabled
                                      ? kSecondaryText.withValues(alpha: 0.2)
                                      : kAccent,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.foundryOrManufacturer.isNotEmpty
                                            ? e.foundryOrManufacturer
                                            : 'Unknown Maker',
                                        style: GoogleFonts.ibmPlexSans(
                                          color: isDisabled
                                              ? kSecondaryText
                                              : kPrimaryText,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        e.vaultControlNumber,
                                        style: GoogleFonts.ibmPlexMono(
                                          color: kSecondaryText,
                                          fontSize: 9.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(projectProvider).entries;

    final alpha = _alphaId != null
        ? entries
            .cast<SafetyLampModel?>()
            .firstWhere((e) => e?.id == _alphaId, orElse: () => null)
        : null;
    final beta = _betaId != null
        ? entries
            .cast<SafetyLampModel?>()
            .firstWhere((e) => e?.id == _betaId, orElse: () => null)
        : null;

    if ((_alphaId != null && alpha == null) ||
        (_betaId != null && beta == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
            if (alpha == null) _alphaId = null;
            if (beta == null) _betaId = null;
          }));
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          CustomPaint(painter: _ShaftGridPainter(), size: Size.infinite),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildHeader(),
              if (alpha == null && beta == null)
                SliverFillRemaining(
                    hasScrollBody: false, child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSelectorRow(alpha, beta),
                    if (alpha != null && beta != null) ...[
                      SizedBox(height: 24.h),
                      _buildComparisonGrid(alpha, beta),
                    ],
                    SizedBox(height: 150.h),
                  ]),
                ),
            ],
          ),
          if (alpha != null || beta != null)
            Positioned(
              right: 20.w,
              top: MediaQuery.of(context).padding.top + 24.h,
              child: GestureDetector(
                onTap: () =>
                    setState(() {
                      _alphaId = null;
                      _betaId = null;
                    }),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: kPanelBg,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: kOutline),
                  ),
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverPadding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24.h, bottom: 16.h),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DUAL ANALYSIS',
                style: GoogleFonts.ibmPlexMono(
                  color: kAccent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Compare\nLamps',
                style: GoogleFonts.playfairDisplay(
                  color: kPrimaryText,
                  fontSize: 36.sp,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kAccent.withValues(alpha: 0.05),
              border: Border.all(
                  color: kAccent.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Icon(Icons.local_fire_department_outlined,
                color: kAccent.withValues(alpha: 0.3), size: 48.sp),
          ),
          SizedBox(height: 32.h),
          Text(
            'SELECT TWO SPECIMENS',
            style: GoogleFonts.ibmPlexMono(
              color: kPrimaryText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              'Tap the slots below to load lamps and compare their specifications side by side.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 13.sp,
                height: 1.55,
              ),
            ),
          ),
          SizedBox(height: 40.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEmptySlot(true),
              SizedBox(width: 20.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: kPanelBg,
                  borderRadius: BorderRadius.circular(kRadiusPill),
                  border: Border.all(color: kOutline),
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              _buildEmptySlot(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(bool isAlpha) {
    return GestureDetector(
      onTap: () => _showSelectionSheet(context, isAlpha),
      child: Container(
        width: 100.w,
        height: 120.h,
        decoration: BoxDecoration(
          border: Border.all(
              color: kOutline, width: 1.5),
          borderRadius: BorderRadius.circular(kRadiusStandard),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded,
                color: kSecondaryText.withValues(alpha: 0.35), size: 28.sp),
            SizedBox(height: 6.h),
            Text(
              isAlpha ? 'ALPHA' : 'BETA',
              style: GoogleFonts.ibmPlexMono(
                  color: kSecondaryText,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorRow(SafetyLampModel? alpha, SafetyLampModel? beta) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: alpha != null
                ? _buildSelectorCard(true, alpha)
                : _buildEmptySlot(true),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 8.w,
              right: 8.w,
              top: 12.h,
            ),
            child: LiquidGlass.withOwnLayer(
              settings: const LiquidGlassSettings(
                blur: 35,
                glassColor: Color(0x80D4920A),
                saturation: 1.4,
                lightIntensity: 0.7,
                thickness: 10,
              ),
              shape: const LiquidRoundedSuperellipse(borderRadius: 999),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRadiusPill),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.ibmPlexMono(
                    color: kBackground,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: beta != null
                ? _buildSelectorCard(false, beta)
                : _buildEmptySlot(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard(bool isAlpha, SafetyLampModel node) {
    final imageProv = ref.watch(imageProvider);
    final imagePath = imageProv.getImagePath(node.photoPath);
    final gdcColor = getGasDetectionColor(node.gasDetectionClass);

    return GestureDetector(
      onTap: () {
        setState(() => isAlpha ? _alphaId = null : _betaId = null);
      },
      child: LiquidGlass.withOwnLayer(
        settings: const LiquidGlassSettings(
          blur: 40,
          glassColor: Color(0x20F2EDE4),
          saturation: 1.2,
          lightIntensity: 0.4,
          thickness: 12,
        ),
        shape: const LiquidRoundedRectangle(borderRadius: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusStandard),
            border: Border.all(
                color: kAccent.withValues(alpha: 0.3), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                color: isAlpha ? kAccent : kSecondaryAccent,
                child: Text(
                  isAlpha ? 'ALPHA' : 'BETA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexMono(
                    color: kBackground,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(kRadiusSubtle),
                      child: SizedBox(
                        height: 70.h,
                        width: double.infinity,
                        child: (imagePath != null &&
                                File(imagePath).existsSync())
                            ? Image.file(File(imagePath), fit: BoxFit.cover)
                            : Container(
                                color: kBackground,
                                child: Center(
                                  child: Icon(
                                    Icons.local_fire_department_outlined,
                                    color: kSecondaryText.withValues(alpha: 0.15),
                                    size: 28.sp,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      node.foundryOrManufacturer.isEmpty
                          ? 'Unknown'
                          : node.foundryOrManufacturer,
                      style: GoogleFonts.playfairDisplay(
                        color: kPrimaryText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      node.vaultControlNumber,
                      style: GoogleFonts.ibmPlexMono(
                          color: kSecondaryText, fontSize: 7.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: gdcColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(kRadiusPill),
                      ),
                      child: Text(
                        node.gasDetectionClass.label.toUpperCase(),
                        style: GoogleFonts.ibmPlexMono(
                          color: gdcColor,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonGrid(SafetyLampModel alpha, SafetyLampModel beta) {
    final fields = [
      _FieldData('CLASSIFICATION', alpha.apparatusClassification.label,
          beta.apparatusClassification.label),
      _FieldData('VAULT CODE', alpha.vaultControlNumber, beta.vaultControlNumber),
      _FieldData('GAS DETECTION', alpha.gasDetectionClass.label,
          beta.gasDetectionClass.label),
      _FieldData('GAUZE CONFIG', alpha.gauzeConfiguration, beta.gauzeConfiguration),
      _FieldData('ERA', alpha.eraOfProduction, beta.eraOfProduction),
      _FieldData('FUEL', alpha.fuelAndIlluminant, beta.fuelAndIlluminant),
      _FieldData('BODY METAL', alpha.bodyMetal.label, beta.bodyMetal.label),
      _FieldData('LOCKING', alpha.lockingMechanismType.label,
          beta.lockingMechanismType.label),
      _FieldData('PRESERVATION', alpha.preservationStatus.label.split(' — ')[0],
          beta.preservationStatus.label.split(' — ')[0]),
    ];

    final matchCount = fields.where((f) => f.match).length;
    final total = fields.length;
    final similarity = (matchCount / total * 100).round();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          _buildSimilarityBar(similarity),
          SizedBox(height: 20.h),
          ...fields.map((field) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _buildFieldDiff(field),
          )),
        ],
      ),
    );
  }

  Widget _buildSimilarityBar(int percent) {
    final color = percent >= 70
        ? const Color(0xFF22C55E)
        : percent >= 40
            ? kAccent
            : kSecondaryAccent;
    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        blur: 40,
        glassColor: Color(0x25F2EDE4),
        saturation: 1.2,
        lightIntensity: 0.4,
        thickness: 12,
      ),
      shape: const LiquidRoundedRectangle(borderRadius: 16),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusStandard),
          border: Border.all(color: kOutline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPECIMEN SIMILARITY',
                    style: GoogleFonts.ibmPlexMono(
                      color: kSecondaryText,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: kOutline,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6.h,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              '$percent%',
              style: GoogleFonts.ibmPlexMono(
                color: color,
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldDiff(_FieldData field) {
    final a = field.a.isEmpty ? '—' : field.a;
    final b = field.b.isEmpty ? '—' : field.b;

    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        blur: 35,
        glassColor: Color(0x18F2EDE4),
        saturation: 1.1,
        lightIntensity: 0.3,
        thickness: 8,
      ),
      shape: const LiquidRoundedRectangle(borderRadius: 10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          border: Border.all(
            color: field.match ? kOutline : kAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  field.match
                      ? Icons.check_circle_outline
                      : Icons.remove_circle_outline,
                  size: 12.sp,
                  color: field.match
                      ? const Color(0xFF22C55E)
                      : kAccent,
                ),
                SizedBox(width: 6.w),
                Text(
                  field.label,
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    a,
                    style: GoogleFonts.ibmPlexSans(
                      color: field.match ? kPrimaryText : kAccent,
                      fontSize: 12.sp,
                      fontWeight: field.match
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(kRadiusPill),
                      border: Border.all(color: kOutline),
                    ),
                    child: Text(
                      'vs',
                      style: GoogleFonts.ibmPlexMono(
                          color: kSecondaryText,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    b,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.ibmPlexSans(
                      color: field.match ? kPrimaryText : kSecondaryAccent,
                      fontSize: 12.sp,
                      fontWeight: field.match
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldData {
  final String label;
  final String a;
  final String b;
  bool get match =>
      a.trim().toLowerCase() == b.trim().toLowerCase() &&
      a.isNotEmpty &&
      b.isNotEmpty;

  _FieldData(this.label, this.a, this.b);
}
