import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:the_safety_lamp_vault/enum/my_enums.dart';
import 'package:the_safety_lamp_vault/models/project_model.dart';
import 'package:the_safety_lamp_vault/providers/image_provider.dart';
import 'package:the_safety_lamp_vault/providers/input_provider.dart';
import 'package:the_safety_lamp_vault/providers/project_provider.dart';
import 'package:the_safety_lamp_vault/providers/search_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  GasDetectionClass? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProv = ref.watch(searchProvider);
    final allEntries = ref.watch(projectProvider).entries;

    final filterText = searchProv.searchQuery.toLowerCase();
    List<SafetyLampModel> entries = allEntries.where((e) {
      final matchesSearch = filterText.isEmpty ||
          e.foundryOrManufacturer.toLowerCase().contains(filterText) ||
          e.vaultControlNumber.toLowerCase().contains(filterText) ||
          e.apparatusClassification.label.toLowerCase().contains(filterText) ||
          e.historicalContext.toLowerCase().contains(filterText);
      final matchesFilter = _selectedFilter == null || e.gasDetectionClass == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    final navBarHeight = 68.h + 16.h + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Subtle mine shaft grid background
          CustomPaint(painter: _ShaftGridPainter(), size: Size.infinite),
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildHeader(allEntries.length),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      SizedBox(height: 16.h),
                      _buildGasDetectionFilter(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              if (entries.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverWovenGridDelegate.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      pattern: [
                        WovenGridTile(0.78),
                        WovenGridTile(0.78),
                      ],
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = entries[index];
                        final mainIndex = allEntries.indexOf(entry);
                        return _buildGridCard(entry, mainIndex);
                      },
                      childCount: entries.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: navBarHeight + 40.h)),
            ],
          ),
          Positioned(
            right: 20.w,
            bottom: navBarHeight + 16.h,
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        ref.read(inputProvider).clearAll();
        ref.read(imageProvider).clearImage();
        Navigator.pushNamed(context, '/add_screen');
      },
      child: Container(
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(kRadiusPill),
          boxShadow: const [kShadowBlue],
          border: Border.all(color: kPrimaryText.withValues(alpha: 0.15), width: 1.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: kBackground, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'REGISTER LAMP',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: kBackground,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return SliverPadding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24.h, bottom: 16.h),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THE VAULT',
                style: GoogleFonts.ibmPlexMono(
                  color: kSecondaryText,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Safety Lamp\nArchive',
                      style: GoogleFonts.playfairDisplay(
                        color: kPrimaryText,
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: kPanelBg,
                      borderRadius: BorderRadius.circular(kRadiusSubtle),
                      border: Border.all(color: kAccent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      count.toString().padLeft(2, '0'),
                      style: GoogleFonts.ibmPlexMono(
                        color: kAccent,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
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

  Widget _buildSearchBar() {
    final isFocused = _searchFocusNode.hasFocus;
    return Container(
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusSubtle),
        border: Border.all(
          color: isFocused ? kAccent : kOutline,
          width: isFocused ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (v) => ref.read(searchProvider.notifier).setSearchQuery(v),
        style: GoogleFonts.ibmPlexSans(color: kPrimaryText, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Search makers, vault codes, coalfields...',
          hintStyle: GoogleFonts.ibmPlexSans(
            color: kSecondaryText.withValues(alpha: 0.6),
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isFocused ? kAccent : kSecondaryText,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).setSearchQuery('');
                  },
                  child: Icon(Icons.close_rounded, color: kSecondaryText),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildGasDetectionFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(null, 'ALL'),
          ...GasDetectionClass.values.map((g) => _buildFilterChip(g, g.label)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(GasDetectionClass? gdc, String label) {
    final isSelected = _selectedFilter == gdc;
    final color = gdc != null ? getGasDetectionColor(gdc) : kPrimaryText;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = gdc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusPill),
          border: Border.all(
            color: isSelected ? color : kOutline,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (gdc != null) ...[
              Container(
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 7.w),
            ],
            Text(
              label.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                color: isSelected ? color : kSecondaryText,
                fontSize: 9.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(top: 80.h),
      child: Center(
        child: Column(
          children: [
            CustomPaint(
              size: Size(40.w, 56.h),
              painter: _GauzeMotifPainter(
                flameColor: kSecondaryText.withValues(alpha: 0.2),
                isHazard: false,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'NO LAMPS IN THIS VAULT.',
              style: GoogleFonts.ibmPlexMono(
                color: kSecondaryText,
                fontSize: 11.sp,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(SafetyLampModel entry, int mainIndex) {
    final imageProv = ref.watch(imageProvider);
    final imagePath = imageProv.getImagePath(entry.photoPath);
    final gdcColor = getGasDetectionColor(entry.gasDetectionClass);
    final hazard = isHazardLamp(entry.preservationStatus, entry.gasDetectionClass);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.45,
              child: Hero(
                tag: 'grid_img_$mainIndex',
                child: (imagePath != null && File(imagePath).existsSync())
                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                    : Container(
                        color: Colors.transparent,
                        child: Center(
                          child: CustomPaint(
                            size: Size(28.w, 40.h),
                            painter: _GauzeMotifPainter(
                              flameColor: hazard
                                  ? kSecondaryAccent.withValues(alpha: 0.4)
                                  : kAccent.withValues(alpha: 0.25),
                              isHazard: hazard,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            // Gas detection class badge top-left
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: gdcColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(kRadiusPill),
                ),
                child: Text(
                  entry.gasDetectionClass.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 6.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Hazard indicator top-right
            if (hazard)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: kSecondaryAccent,
                    shape: BoxShape.circle,
                    boxShadow: const [kShadowDanger],
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.foundryOrManufacturer.isNotEmpty
                    ? entry.foundryOrManufacturer
                    : 'Unknown Maker',
                style: GoogleFonts.playfairDisplay(
                  color: kPrimaryText,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                entry.vaultControlNumber,
                style: GoogleFonts.ibmPlexMono(
                  color: kSecondaryText,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.fuelAndIlluminant.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: kAccent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    entry.fuelAndIlluminant,
                    style: GoogleFonts.ibmPlexMono(
                      color: kAccent,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (entry.eraOfProduction.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 10.sp,
                      color: kSecondaryText.withValues(alpha: 0.4),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      entry.eraOfProduction,
                      style: GoogleFonts.ibmPlexMono(
                        color: kSecondaryText,
                        fontSize: 8.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/info_screen',
        arguments: {'index': mainIndex},
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius: BorderRadius.circular(kRadiusSubtle),
          border: Border.all(
            color: hazard
                ? kSecondaryAccent.withValues(alpha: 0.3)
                : kOutline,
            width: 1.0,
          ),
          boxShadow: const [kShadowSubtle],
        ),
        clipBehavior: Clip.antiAlias,
        child: cardContent,
      ),
    );
  }
}

// ── Shaft grid background ─────────────────────────────────────────────────────
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

// ── Gauze cylinder motif for cards ───────────────────────────────────────────
/// Minimal front-facing representation of a safety lamp's wire gauze cylinder.
/// Gold flame = operational. Red-tinted flame = disaster provenance / damage.
class _GauzeMotifPainter extends CustomPainter {
  final Color flameColor;
  final bool isHazard;

  _GauzeMotifPainter({required this.flameColor, required this.isHazard});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cx = size.width / 2;

    final cylColor = flameColor.withValues(alpha: 0.5);
    final cylPaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Cylinder body
    final cylW = size.width * 0.32;
    final cylTop = size.height * 0.32;
    final cylBot = size.height * 0.76;
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW, cylTop, cx + cylW, cylBot),
      cylPaint,
    );

    // Crosshatch gauze lines
    final hPaint = Paint()
      ..color = cylColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.6;
    final step = (cylBot - cylTop) / 5;
    for (int row = 1; row < 5; row++) {
      final y = cylTop + row * step;
      canvas.drawLine(Offset(cx - cylW, y), Offset(cx + cylW, y), hPaint);
    }
    final vStep = cylW * 2 / 4;
    for (int col = 1; col < 4; col++) {
      final x = cx - cylW + col * vStep;
      canvas.drawLine(Offset(x, cylTop), Offset(x, cylBot), hPaint);
    }

    // Base reservoir
    final basePaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW * 1.4, cylBot, cx + cylW * 1.4, cylBot + size.height * 0.14),
      basePaint,
    );

    // Bonnet cap line
    canvas.drawLine(
      Offset(cx - cylW * 1.2, cylTop),
      Offset(cx + cylW * 1.2, cylTop),
      basePaint,
    );

    // Flame
    final flamePaint = Paint()
      ..color = flameColor
      ..style = PaintingStyle.fill;
    final flameH = size.height * 0.20;
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
  bool shouldRepaint(covariant _GauzeMotifPainter old) =>
      old.flameColor != flameColor || old.isHazard != isHazard;
}
