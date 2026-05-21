import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_safety_lamp_vault/providers/image_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

void photoBottomSheet(
  BuildContext context,
  ImageNotifier imageProv,
  int index,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _PhotoSheet(imageProv: imageProv, ctx: ctx),
  );
}

class _PhotoSheet extends StatefulWidget {
  final ImageNotifier imageProv;
  final BuildContext ctx;
  const _PhotoSheet({required this.imageProv, required this.ctx});

  @override
  State<_PhotoSheet> createState() => _PhotoSheetState();
}

class _PhotoSheetState extends State<_PhotoSheet>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    Navigator.pop(widget.ctx);
    await widget.imageProv.pickImage(source: source);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - _entryAnim.value) * 60),
        child: Opacity(opacity: _entryAnim.value, child: child),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 36.h + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: kPanelBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(kRadiusLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold accent strip — replaces generic drag handle
            Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    kAccent.withValues(alpha: 0.7),
                    kAccent,
                    kAccent.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kRadiusLarge),
                ),
              ),
            ),
            SizedBox(height: 28.h),

            // Lamp icon + title row
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: kAccentSurface,
                    borderRadius: BorderRadius.circular(kRadiusSubtle),
                    border: Border.all(
                        color: kAccent.withValues(alpha: 0.25), width: 1),
                  ),
                  child: CustomPaint(
                    painter: _SheetLampPainter(),
                  ),
                ),
                SizedBox(width: 14.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHOTOGRAPH SPECIMEN',
                      style: GoogleFonts.ibmPlexMono(
                        color: kAccent,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Add a visual record to this lamp entry',
                      style: GoogleFonts.ibmPlexSans(
                        color: kSecondaryText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Two side-by-side option cards
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    label: 'CAPTURE',
                    sublabel: 'Open camera',
                    icon: Icons.camera_alt_outlined,
                    accentColor: kAccent,
                    onTap: () => _pick(ImageSource.camera),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildOptionCard(
                    label: 'LIBRARY',
                    sublabel: 'Choose existing',
                    icon: Icons.photo_library_outlined,
                    accentColor: const Color(0xFF607D8B),
                    onTap: () => _pick(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // Cancel
            GestureDetector(
              onTap: () => Navigator.pop(widget.ctx),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(kRadiusSubtle),
                  border: Border.all(color: kOutline, width: 1),
                ),
                child: Text(
                  'CANCEL',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexMono(
                    color: kSecondaryText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 18.h),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(kRadiusStandard),
          border: Border.all(color: kOutline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(kRadiusSubtle),
                border:
                    Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, color: accentColor, size: 22.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                color: kPrimaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              sublabel,
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 12.h),
            // Gold/accent bottom accent line
            Container(
              width: 28.w,
              height: 2,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(kRadiusPill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Miniature gauze lamp icon for the sheet header ────────────────────────────
class _SheetLampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cylColor = kAccent.withValues(alpha: 0.55);
    final cylW = size.width * 0.18;
    final cylTop = cy - size.height * 0.18;
    final cylBot = cy + size.height * 0.12;

    final p = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW, cylTop, cx + cylW, cylBot),
      p,
    );

    final hp = Paint()
      ..color = cylColor.withValues(alpha: 0.45)
      ..strokeWidth = 0.6;
    for (int i = 1; i < 4; i++) {
      final y = cylTop + i * (cylBot - cylTop) / 4;
      canvas.drawLine(Offset(cx - cylW, y), Offset(cx + cylW, y), hp);
    }
    // Two vertical gauze lines
    canvas.drawLine(
        Offset(cx - cylW / 3, cylTop), Offset(cx - cylW / 3, cylBot), hp);
    canvas.drawLine(
        Offset(cx + cylW / 3, cylTop), Offset(cx + cylW / 3, cylBot), hp);

    // Base
    canvas.drawRect(
      Rect.fromLTRB(
          cx - cylW * 1.4, cylBot, cx + cylW * 1.4, cylBot + size.height * 0.1),
      p,
    );
    // Bonnet line
    canvas.drawLine(
        Offset(cx - cylW * 1.2, cylTop), Offset(cx + cylW * 1.2, cylTop), p);

    // Flame
    final fp = Paint()
      ..color = kAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final fh = size.height * 0.14;
    final fPath = Path();
    fPath.moveTo(cx - cylW * 0.6, cylTop);
    fPath.quadraticBezierTo(cx, cylTop - fh, cx, cylTop - fh);
    fPath.quadraticBezierTo(cx, cylTop - fh, cx + cylW * 0.6, cylTop);
    fPath.close();
    canvas.drawPath(fPath, fp);
  }

  @override
  bool shouldRepaint(covariant _SheetLampPainter old) => false;
}
