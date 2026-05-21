import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_safety_lamp_vault/screens/home_screen.dart';
import 'package:the_safety_lamp_vault/screens/compare_screen.dart';
import 'package:the_safety_lamp_vault/screens/stats_screen.dart';
import 'package:the_safety_lamp_vault/screens/showcase_screen.dart';
import 'package:the_safety_lamp_vault/utils/const.dart';
import 'package:google_fonts/google_fonts.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final int index;
  const MainNavigation({super.key, this.index = 0});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;

  final List<Widget> _screens = const [
    HomeScreen(),
    CompareScreen(),
    ShowcaseScreen(),
    StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setIndex(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: 16.h + MediaQuery.of(context).padding.bottom,
            child: _buildNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: kPanelBg,
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: kOutline, width: 1.5),
        boxShadow: const [kShadowFloat],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusPill),
        child: Container(
          height: 68.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(0, Icons.archive_outlined, 'Vault'),
              _buildNavItem(1, Icons.compare_arrows_rounded, 'Compare'),
              _buildNavItem(2, Icons.local_fire_department_outlined, 'Shaft'),
              _buildNavItem(3, Icons.menu_book_outlined, 'Logbook'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16.w : 12.w),
        decoration: BoxDecoration(
          color: isSelected ? kAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kBackground : kSecondaryText,
              size: 20.sp,
            ),
            if (isSelected) ...[
              SizedBox(width: 8.w),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.ibmPlexMono(
                  color: kBackground,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
