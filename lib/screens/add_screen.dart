import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_safety_lamp_vault/common/photo_bottom_sheet.dart';
import 'package:the_safety_lamp_vault/enum/my_enums.dart';
import 'package:the_safety_lamp_vault/providers/image_provider.dart';
import 'package:the_safety_lamp_vault/providers/input_provider.dart';
import 'package:the_safety_lamp_vault/providers/project_provider.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class AddScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  final int currentIndex;
  const AddScreen({super.key, this.isEdit = false, this.currentIndex = 0});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageCtrl;
  int _currentPage = 0;
  late AnimationController _shakeCtrl;
  bool _showVaultError = false;

  late TextEditingController _vaultCtrl;
  late TextEditingController _foundryCtrl;
  late TextEditingController _eraCtrl;
  late TextEditingController _gauzeCtrl;
  late TextEditingController _fuelCtrl;
  late TextEditingController _airCtrl;
  late TextEditingController _dimCtrl;
  late TextEditingController _gearCtrl;
  late TextEditingController _stampsCtrl;
  late TextEditingController _contextCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    final p = ref.read(inputProvider);
    _vaultCtrl = TextEditingController(text: p.vaultControlNumber);
    _foundryCtrl = TextEditingController(text: p.foundryOrManufacturer);
    _eraCtrl = TextEditingController(text: p.eraOfProduction);
    _gauzeCtrl = TextEditingController(text: p.gauzeConfiguration);
    _fuelCtrl = TextEditingController(text: p.fuelAndIlluminant);
    _airCtrl = TextEditingController(text: p.airInflowDesign);
    _dimCtrl = TextEditingController(text: p.physicalProportions);
    _gearCtrl = TextEditingController(text: p.accompanyingGear);
    _stampsCtrl = TextEditingController(text: p.inspectorAndCollieryStamps);
    _contextCtrl = TextEditingController(text: p.historicalContext);
    _notesCtrl = TextEditingController(text: p.archivalNotes);
    _vaultCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _shakeCtrl.dispose();
    for (final c in [
      _vaultCtrl, _foundryCtrl, _eraCtrl, _gauzeCtrl, _fuelCtrl,
      _airCtrl, _dimCtrl, _gearCtrl, _stampsCtrl, _contextCtrl, _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToPage(int page) => _pageCtrl.animateToPage(
    page,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeInOut,
  );

  void _triggerVaultError() {
    setState(() => _showVaultError = true);
    _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showVaultError = false);
    });
  }

  void _save() async {
    final p = ref.read(inputProvider);
    p.vaultControlNumber = _vaultCtrl.text.trim();
    p.foundryOrManufacturer = _foundryCtrl.text;
    p.eraOfProduction = _eraCtrl.text;
    p.gauzeConfiguration = _gauzeCtrl.text;
    p.fuelAndIlluminant = _fuelCtrl.text;
    p.airInflowDesign = _airCtrl.text;
    p.physicalProportions = _dimCtrl.text;
    p.accompanyingGear = _gearCtrl.text;
    p.inspectorAndCollieryStamps = _stampsCtrl.text;
    p.historicalContext = _contextCtrl.text;
    p.archivalNotes = _notesCtrl.text;

    if (_vaultCtrl.text.trim().isEmpty) {
      _goToPage(0);
      _triggerVaultError();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SavingDialog(),
    );
    await Future.delayed(const Duration(milliseconds: 1100));

    if (widget.isEdit) {
      ref.read(projectProvider).editEntry(ref, widget.currentIndex);
    } else {
      ref.read(projectProvider).addEntry(ref);
    }

    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      ref.read(inputProvider).clearAll();
      ref.read(imageProvider).clearImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: kPrimaryText, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit ? 'EDIT LAMP RECORD' : 'REGISTER LAMP',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: kAccent,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(20.h),
          child: _buildStepIndicator(),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 2.h),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [_buildPage1(), _buildPage2(), _buildPage3()],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 10.h),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6.w : 0),
              height: 3.h,
              decoration: BoxDecoration(
                color: isActive ? kAccent : kOutline,
                borderRadius: BorderRadius.circular(kRadiusPill),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('01', 'Registry'),
          SizedBox(height: 24.h),
          _buildPhotoSection(),
          SizedBox(height: 28.h),
          // Vault control number with shake + inline error
          AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (context, child) {
              final shake = _shakeCtrl.isAnimating
                  ? (8.0 * (0.5 - (_shakeCtrl.value - 0.5).abs()) *
                      ((_shakeCtrl.value * 14).floor().isEven ? 1 : -1))
                  : 0.0;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _monoField(
                  label: 'VAULT CONTROL NUMBER',
                  ctrl: _vaultCtrl,
                  hint: 'e.g. SLV-WOLF-1912-PA-089',
                  hasError: _showVaultError,
                  onChanged: (v) {
                    ref.read(inputProvider).vaultControlNumber = v;
                    if (_showVaultError && v.trim().isNotEmpty) {
                      setState(() => _showVaultError = false);
                    }
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _showVaultError
                      ? Container(
                          margin: EdgeInsets.only(top: 6.h, bottom: 12.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: kAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(kRadiusSubtle),
                            border: Border.all(
                                color: kAccent.withValues(alpha: 0.4),
                                width: 1.0),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: kAccent, size: 14.sp),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'A vault control number is required before committing this record.',
                                  style: GoogleFonts.ibmPlexSans(
                                    color: kAccent,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          _buildEnumGroup<ApparatusClassification>(
            label: 'APPARATUS CLASSIFICATION',
            values: ApparatusClassification.values,
            current: ref.watch(inputProvider).apparatusClassification,
            onSelected: (t) => ref.read(inputProvider).apparatusClassification = t,
            labelBuilder: (t) => t.label,
          ),
          _monoField(
            label: 'FOUNDRY OR MANUFACTURER',
            ctrl: _foundryCtrl,
            hint: 'e.g. Wolf Safety Lamp Co., Koehler',
            onChanged: (v) => ref.read(inputProvider).foundryOrManufacturer = v,
          ),
          _monoField(
            label: 'ERA OF PRODUCTION',
            ctrl: _eraCtrl,
            hint: 'e.g. 1910s',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9s]')),
              _EraInputFormatter(),
            ],
            onChanged: (v) => ref.read(inputProvider).eraOfProduction = v,
          ),
          _buildEnumGroup<GasDetectionClass>(
            label: 'GAS DETECTION CLASS',
            values: GasDetectionClass.values,
            current: ref.watch(inputProvider).gasDetectionClass,
            onSelected: (t) => ref.read(inputProvider).gasDetectionClass = t,
            labelBuilder: (t) => t.label,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('02', 'Technical Specs'),
          SizedBox(height: 24.h),
          _monoField(
            label: 'GAUZE CONFIGURATION',
            ctrl: _gauzeCtrl,
            hint: 'e.g. Double gauze, 28 mesh/inch, copper mesh',
            onChanged: (v) => ref.read(inputProvider).gauzeConfiguration = v,
          ),
          _monoField(
            label: 'FUEL & ILLUMINANT',
            ctrl: _fuelCtrl,
            hint: 'e.g. Naphtha, calcium carbide, whale oil, kerosene',
            onChanged: (v) => ref.read(inputProvider).fuelAndIlluminant = v,
          ),
          _buildEnumGroup<LockingMechanism>(
            label: 'LOCKING MECHANISM',
            values: LockingMechanism.values,
            current: ref.watch(inputProvider).lockingMechanismType,
            onSelected: (t) => ref.read(inputProvider).lockingMechanismType = t,
            labelBuilder: (t) => t.label,
          ),
          _buildEnumGroup<BodyMetal>(
            label: 'BODY METAL & METALLURGY',
            values: BodyMetal.values,
            current: ref.watch(inputProvider).bodyMetal,
            onSelected: (t) => ref.read(inputProvider).bodyMetal = t,
            labelBuilder: (t) => t.label,
          ),
          _monoField(
            label: 'AIR-INFLOW DESIGN',
            ctrl: _airCtrl,
            hint: 'e.g. Bottom-feed air ring, top-feed tubes',
            onChanged: (v) => ref.read(inputProvider).airInflowDesign = v,
          ),
          _monoField(
            label: 'PHYSICAL PROPORTIONS',
            ctrl: _dimCtrl,
            hint: 'e.g. 340mm total height, 85mm reflector, 420g',
            onChanged: (v) => ref.read(inputProvider).physicalProportions = v,
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('03', 'Archival Record'),
          SizedBox(height: 24.h),
          _buildEnumGroup<PreservationStatus>(
            label: 'PRESERVATION STATUS',
            values: PreservationStatus.values,
            current: ref.watch(inputProvider).preservationStatus,
            onSelected: (t) => ref.read(inputProvider).preservationStatus = t,
            labelBuilder: (t) => t.label.split(' — ')[0],
          ),
          _monoField(
            label: 'ACCOMPANYING GEAR',
            ctrl: _gearCtrl,
            hint: 'Magnetic keys, tip cleaners, leather straps, spare glass...',
            maxLines: 2,
            onChanged: (v) => ref.read(inputProvider).accompanyingGear = v,
          ),
          _monoField(
            label: 'INSPECTOR & COLLIERY STAMPS',
            ctrl: _stampsCtrl,
            hint: 'Mine inspector numbers, railroad tags, coal company inventory...',
            maxLines: 2,
            onChanged: (v) => ref.read(inputProvider).inspectorAndCollieryStamps = v,
          ),
          _monoField(
            label: 'COLLIERY PROVENANCE',
            ctrl: _contextCtrl,
            hint: 'e.g. Welsh valleys, Durham Coalfield, Appalachian, Ruhr Basin',
            onChanged: (v) => ref.read(inputProvider).historicalContext = v,
          ),
          _monoField(
            label: 'ARCHIVAL NOTES',
            ctrl: _notesCtrl,
            hint: 'History, gas detection incidents, notable colliery use...',
            maxLines: 5,
            onChanged: (v) => ref.read(inputProvider).archivalNotes = v,
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String num, String title) {
    return Row(
      children: [
        Text(
          num,
          style: GoogleFonts.ibmPlexMono(
            color: kAccent,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 12.w),
        Container(width: 24.w, height: 1, color: kOutline),
        SizedBox(width: 12.w),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: kPrimaryText,
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    final imgPath = ref.watch(imageProvider).getImagePath(
      ref.watch(imageProvider).resultImage,
    );
    final hasImage = imgPath != null && File(imgPath).existsSync();

    return GestureDetector(
      onTap: () => photoBottomSheet(context, ref.read(imageProvider), 0, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusStandard),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                color: kPanelBg,
              ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(imgPath), fit: BoxFit.cover),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 60.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  kBackground.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PhotoGridPainter(),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 28.w,
                                    height: 1,
                                    color: kOutline,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'SPECIMEN PHOTOGRAPH',
                                    style: GoogleFonts.ibmPlexMono(
                                      color: kSecondaryText.withValues(alpha: 0.6),
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Container(
                                    width: 28.w,
                                    height: 1,
                                    color: kOutline,
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              CustomPaint(
                                size: Size(38.w, 54.h),
                                painter: _PhotoLampPainter(),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'TAP TO PHOTOGRAPH',
                                style: GoogleFonts.ibmPlexMono(
                                  color: kPrimaryText.withValues(alpha: 0.7),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Camera · Photo library',
                                style: GoogleFonts.ibmPlexSans(
                                  color: kSecondaryText.withValues(alpha: 0.5),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadiusStandard),
                    border: Border.all(
                      color: hasImage
                          ? kAccent.withValues(alpha: 0.35)
                          : kOutline,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            if (hasImage)
              Positioned(
                bottom: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: kBackground.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(kRadiusPill),
                    border: Border.all(color: kOutline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: kAccent, size: 12.sp),
                      SizedBox(width: 6.w),
                      Text(
                        'RETAKE',
                        style: GoogleFonts.ibmPlexMono(
                          color: kAccent,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _monoField({
    required String label,
    required TextEditingController ctrl,
    required Function(String) onChanged,
    String? hint,
    int maxLines = 1,
    bool hasError = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: hasError ? kAccent : kSecondaryText,
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: ctrl,
            onChanged: onChanged,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.ibmPlexSans(
              color: kPrimaryText,
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.ibmPlexSans(
                color: kSecondaryText.withValues(alpha: 0.35),
                fontSize: 13.sp,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: hasError ? kAccent.withValues(alpha: 0.5) : kOutline,
                  width: 1.0,
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kAccent, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnumGroup<T>({
    required String label,
    required List<T> values,
    required T current,
    required Function(T) onSelected,
    required String Function(T) labelBuilder,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              color: kSecondaryText,
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: values.map((val) {
              final isSel = val == current;
              return GestureDetector(
                onTap: () => onSelected(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 190),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSel ? kAccent : kPanelBg,
                    borderRadius: BorderRadius.circular(kRadiusSubtle),
                    border: Border.all(
                      color: isSel ? kAccent : kOutline,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    labelBuilder(val),
                    style: GoogleFonts.ibmPlexSans(
                      color: isSel ? kBackground : kPrimaryText,
                      fontSize: 12.sp,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: kBackground,
        border: const Border(top: BorderSide(color: kOutline, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: GestureDetector(
                onTap: () => _goToPage(_currentPage - 1),
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: kPanelBg,
                    borderRadius: BorderRadius.circular(kRadiusSubtle),
                    border: Border.all(color: kOutline, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '← BACK',
                      style: GoogleFonts.ibmPlexMono(
                        color: kPrimaryText,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Builder(builder: (context) {
              final isIdEmpty = _vaultCtrl.text.trim().isEmpty;
              final isDisabled = _currentPage == 0 && isIdEmpty;
              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : () {
                        if (_currentPage < 2) {
                          _goToPage(_currentPage + 1);
                        } else {
                          _save();
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 190),
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: isDisabled ? kOutline : kAccent,
                    borderRadius: BorderRadius.circular(kRadiusSubtle),
                    boxShadow: isDisabled ? null : const [kShadowBlue],
                  ),
                  child: Center(
                    child: Text(
                      _currentPage < 2
                          ? 'NEXT →'
                          : (widget.isEdit
                              ? 'UPDATE RECORD'
                              : 'COMMIT TO VAULT'),
                      style: GoogleFonts.ibmPlexMono(
                        color: isDisabled ? kSecondaryText : kBackground,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SavingDialog extends StatelessWidget {
  const _SavingDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kPanelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44.w,
              height: 44.w,
              child: const CircularProgressIndicator(
                color: kAccent,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              'COMMITTING TO VAULT',
              style: GoogleFonts.ibmPlexMono(
                color: kPrimaryText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Recording lamp data to the safety archive.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                color: kSecondaryText,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EraInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final regExp = RegExp(r'^\d{0,4}s?$');
    if (regExp.hasMatch(text)) return newValue;
    return oldValue;
  }
}

// ── Photo section painters ────────────────────────────────────────────────────
class _PhotoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1A14).withValues(alpha: 0.8)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _PhotoGridPainter old) => false;
}

class _PhotoLampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cylColor = const Color(0xFFD4920A).withValues(alpha: 0.28);
    final cylW = size.width * 0.30;
    final cylTop = size.height * 0.30;
    final cylBot = size.height * 0.76;

    final cylPaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW, cylTop, cx + cylW, cylBot),
      cylPaint,
    );

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

    final basePaint = Paint()
      ..color = cylColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(
      Rect.fromLTRB(cx - cylW * 1.4, cylBot, cx + cylW * 1.4, cylBot + size.height * 0.14),
      basePaint,
    );
    canvas.drawLine(
      Offset(cx - cylW * 1.2, cylTop),
      Offset(cx + cylW * 1.2, cylTop),
      basePaint,
    );

    // Flame — brighter
    final flamePaint = Paint()
      ..color = const Color(0xFFD4920A).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final flameH = size.height * 0.20;
    final flamePath = Path();
    flamePath.moveTo(cx - cylW * 0.65, cylTop);
    flamePath.quadraticBezierTo(cx, cylTop - flameH, cx, cylTop - flameH);
    flamePath.quadraticBezierTo(cx, cylTop - flameH, cx + cylW * 0.65, cylTop);
    flamePath.close();
    canvas.drawPath(flamePath, flamePaint);
  }

  @override
  bool shouldRepaint(covariant _PhotoLampPainter old) => false;
}
