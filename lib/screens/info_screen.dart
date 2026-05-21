import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_safety_lamp_vault/providers/image_provider.dart';
import 'package:the_safety_lamp_vault/providers/project_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  void _showDeleteDialog(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: kPanelBg,
            borderRadius: BorderRadius.circular(kRadiusMedium),
            border: Border.all(color: kOutline, width: 1),
            boxShadow: const [kShadowFloat],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: kError.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded, color: kError, size: 28.sp),
              ),
              SizedBox(height: 20.h),
              Text(
                'REMOVE FROM VAULT',
                style: GoogleFonts.ibmPlexMono(
                  color: kPrimaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.sp,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'This lamp record will be permanently removed from the vault. This cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                  color: kSecondaryText,
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: kBackground,
                          borderRadius: BorderRadius.circular(kRadiusSubtle),
                          border: Border.all(color: kOutline),
                        ),
                        child: Center(
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.ibmPlexMono(
                              color: kSecondaryText,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(projectProvider).deleteEntry(index);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: kError,
                          borderRadius: BorderRadius.circular(kRadiusSubtle),
                        ),
                        child: Center(
                          child: Text(
                            'REMOVE',
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final index = args['index'] as int;
    final projectProv = ref.watch(projectProvider);
    if (index >= projectProv.entries.length) {
      return Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Lamp not found.')),
      );
    }
    final entry = projectProv.entries[index];
    final imageProv = ref.watch(imageProvider);
    final imagePath = imageProv.getImagePath(entry.photoPath);
    final gdcColor = getGasDetectionColor(entry.gasDetectionClass);
    final condColor = getConditionColor(entry.preservationStatus);
    final hazard = isHazardLamp(entry.preservationStatus, entry.gasDetectionClass);

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.40,
            stretch: true,
            backgroundColor: kPanelBg,
            leadingWidth: 72.w,
            leading: Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                      border: Border.all(color: kAccent),
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: kPrimaryText, size: 20.sp),
                  ),
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => _showDeleteDialog(context, ref, index),
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(color: kAccent),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: kSecondaryAccent, size: 20.sp),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  ref.read(projectProvider).fillInput(ref, index);
                  Navigator.pushNamed(
                    context,
                    '/add_screen',
                    arguments: {'index': index, 'isEdit': true},
                  );
                },
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(color: kAccent),
                  ),
                  child: Icon(Icons.edit_rounded, color: kPrimaryText, size: 18.sp),
                ),
              ),
              SizedBox(width: 16.w),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Hero(
                tag: 'item-$index',
                child: (entry.photoPath.isNotEmpty &&
                        imagePath != null &&
                        File(imagePath).existsSync())
                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                    : Container(
                        color: kPanelBg,
                        child: Center(
                          child: CustomPaint(
                            size: Size(80.w, 112.h),
                            painter: _InfoGauzePainter(
                              flameColor: hazard
                                  ? kSecondaryAccent.withValues(alpha: 0.6)
                                  : kAccent.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLarge)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Classification + era row
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: kAccentSurface,
                            borderRadius: BorderRadius.circular(kRadiusPill),
                            border: Border.all(
                                color: kAccent.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            entry.apparatusClassification.label,
                            style: GoogleFonts.ibmPlexSans(
                              color: kAccent,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (entry.eraOfProduction.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: kAccentSurface,
                              borderRadius: BorderRadius.circular(kRadiusPill),
                              border: Border.all(
                                  color: kAccent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              entry.eraOfProduction,
                              style: GoogleFonts.ibmPlexMono(
                                color: kAccent,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Manufacturer name in Playfair Display
                    Text(
                      entry.foundryOrManufacturer.isNotEmpty
                          ? entry.foundryOrManufacturer
                          : 'Unknown Maker',
                      style: GoogleFonts.playfairDisplay(
                        color: kPrimaryText,
                        fontSize: 38.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      entry.vaultControlNumber,
                      style: GoogleFonts.ibmPlexMono(
                        color: kSecondaryText,
                        fontSize: 11.sp,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // ── Gas Detection Card ───────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: kPanelBg,
                        borderRadius: BorderRadius.circular(kRadiusSubtle),
                        border: Border.all(color: kOutline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: gdcColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(kRadiusSubtle),
                              border: Border.all(
                                  color: gdcColor.withValues(alpha: 0.25)),
                            ),
                            child: Icon(
                              hazard
                                  ? Icons.warning_amber_rounded
                                  : Icons.local_fire_department_outlined,
                              color: gdcColor,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.gasDetectionClass.label.toUpperCase(),
                                  style: GoogleFonts.ibmPlexMono(
                                    color: gdcColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (entry.gauzeConfiguration.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    entry.gauzeConfiguration,
                                    style: GoogleFonts.ibmPlexMono(
                                      color: kPrimaryText,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'GAUZE CONFIGURATION',
                                    style: GoogleFonts.ibmPlexSans(
                                      color: kSecondaryText,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Fuel badge
                    if (entry.fuelAndIlluminant.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: kAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(kRadiusPill),
                          border: Border.all(
                              color: kAccent.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_gas_station_outlined,
                                color: kAccent, size: 14.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                entry.fuelAndIlluminant,
                                style: GoogleFonts.ibmPlexMono(
                                  color: kAccent,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // Provenance tag
                    if (entry.historicalContext.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: kAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(kRadiusPill),
                          border: Border.all(
                              color: kAccent.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: kAccent, size: 14.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                entry.historicalContext,
                                style: GoogleFonts.ibmPlexSans(
                                  color: kAccent,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 28.h),
                    ],

                    // ── Technical specification ─────────────────────────────
                    _buildSectionHeader('TECHNICAL SPECIFICATION'),
                    SizedBox(height: 16.h),
                    _buildSpecRow('Body Metal', entry.bodyMetal.label),
                    _buildSpecRow('Locking Mechanism', entry.lockingMechanismType.label),
                    _buildSpecRow('Air-Inflow Design', entry.airInflowDesign),
                    _buildSpecRow('Physical Proportions', entry.physicalProportions),
                    _buildConditionRow(
                      'Preservation Status',
                      entry.preservationStatus.label,
                      condColor,
                    ),

                    if (entry.inspectorAndCollieryStamps.isNotEmpty) ...[
                      SizedBox(height: 28.h),
                      _buildSectionHeader('INSPECTOR & COLLIERY STAMPS'),
                      SizedBox(height: 12.h),
                      _buildMonoBox(entry.inspectorAndCollieryStamps),
                    ],

                    if (entry.accompanyingGear.isNotEmpty) ...[
                      SizedBox(height: 28.h),
                      _buildSectionHeader('ACCOMPANYING GEAR'),
                      SizedBox(height: 12.h),
                      _buildMonoBox(entry.accompanyingGear),
                    ],

                    if (entry.archivalNotes.isNotEmpty) ...[
                      SizedBox(height: 28.h),
                      _buildSectionHeader('ARCHIVAL NOTES'),
                      SizedBox(height: 12.h),
                      Text(
                        entry.archivalNotes,
                        style: GoogleFonts.ibmPlexSans(
                          color: kPrimaryText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w300,
                          height: 1.65,
                        ),
                      ),
                    ],

                    SizedBox(height: 120.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 14.h,
          color: kAccent,
        ),
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

  Widget _buildSpecRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ibmPlexSans(
                color: kPrimaryText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(String label, String value, Color color) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 13.sp,
              ),
            ),
          ),
          Container(
            width: 8.w,
            height: 8.w,
            margin: EdgeInsets.only(top: 3.h, right: 8.w),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ibmPlexSans(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonoBox(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(color: kOutline),
      ),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          color: kPrimaryText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }
}

// ── Gauze motif painter for info screen hero fallback ─────────────────────────
class _InfoGauzePainter extends CustomPainter {
  final Color flameColor;
  _InfoGauzePainter({required this.flameColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cylColor = flameColor.withValues(alpha: 0.5);
    final cylPaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final cylW = size.width * 0.3;
    final cylTop = size.height * 0.28;
    final cylBot = size.height * 0.76;

    canvas.drawRect(
      Rect.fromLTRB(cx - cylW, cylTop, cx + cylW, cylBot),
      cylPaint,
    );

    final hPaint = Paint()
      ..color = cylColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    final step = (cylBot - cylTop) / 8;
    for (int row = 1; row < 8; row++) {
      final y = cylTop + row * step;
      canvas.drawLine(Offset(cx - cylW, y), Offset(cx + cylW, y), hPaint);
    }
    final vStep = cylW * 2 / 5;
    for (int col = 1; col < 5; col++) {
      final x = cx - cylW + col * vStep;
      canvas.drawLine(Offset(x, cylTop), Offset(x, cylBot), hPaint);
    }

    final basePaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW * 1.5, cylBot, cx + cylW * 1.5, cylBot + size.height * 0.14),
      basePaint,
    );
    canvas.drawLine(
      Offset(cx - cylW * 1.3, cylTop),
      Offset(cx + cylW * 1.3, cylTop),
      basePaint,
    );

    final flamePaint = Paint()
      ..color = flameColor
      ..style = PaintingStyle.fill;
    final flameH = size.height * 0.18;
    final flamePath = Path();
    flamePath.moveTo(cx - cylW * 0.7, cylTop);
    flamePath.quadraticBezierTo(
      cx - cylW * 0.2, cylTop - flameH * 0.5,
      cx, cylTop - flameH,
    );
    flamePath.quadraticBezierTo(
      cx + cylW * 0.2, cylTop - flameH * 0.5,
      cx + cylW * 0.7, cylTop,
    );
    flamePath.close();
    canvas.drawPath(flamePath, flamePaint);
  }

  @override
  bool shouldRepaint(covariant _InfoGauzePainter old) =>
      old.flameColor != flameColor;
}
