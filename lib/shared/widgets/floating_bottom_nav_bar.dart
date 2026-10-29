import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum NabhTab {
  home,
  insights,
  scan,
  farm,
  chat,
}

class FloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isHindi;
  final String? currentLanguage;

  const FloatingBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isHindi = false,
    this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    final lang = (currentLanguage ?? (isHindi ? 'Hindi' : 'English')).toLowerCase();
    String homeLabel = 'Home';
    String insightsLabel = 'Insights';
    String scanLabel = 'Scan';
    String farmLabel = 'Farm';
    String chatLabel = 'Ask Nabh';

    if (lang.contains('hinglish') || lang == 'hing') {
      homeLabel = 'Home';
      insightsLabel = 'Insights';
      scanLabel = 'Scan';
      farmLabel = 'Khet';
      chatLabel = 'Nabh AI';
    } else if (lang.contains('punjabi') || lang == 'pa') {
      homeLabel = 'ਮੁੱਖ';
      insightsLabel = 'ਜਾਣਕਾਰੀ';
      scanLabel = 'ਸਕੈਨ';
      farmLabel = 'ਖੇਤ';
      chatLabel = 'ਨਭ AI';
    } else if (lang.contains('bengali') || lang == 'bn') {
      homeLabel = 'হোম';
      insightsLabel = 'বিশ্লেষণ';
      scanLabel = 'স্ক্যান';
      farmLabel = 'জমি';
      chatLabel = 'নভ AI';
    } else if (lang.contains('haryanvi') || lang == 'hr') {
      homeLabel = 'घर';
      insightsLabel = 'पड़ताल';
      scanLabel = 'जांच';
      farmLabel = 'खेत';
      chatLabel = 'नभ AI';
    } else if (lang.contains('hindi') || lang == 'hi' || isHindi) {
      homeLabel = 'होम';
      insightsLabel = 'अंतर्दृष्टि';
      scanLabel = 'स्कैन';
      farmLabel = 'खेत';
      chatLabel = 'नभ AI';
    }

    final navItems = [
      _NavItemData(
        label: homeLabel,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
      ),
      _NavItemData(
        label: insightsLabel,
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights,
      ),
      _NavItemData(
        label: scanLabel,
        icon: Icons.qr_code_scanner_outlined,
        activeIcon: Icons.qr_code_scanner,
      ),
      _NavItemData(
        label: farmLabel,
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
      ),
      _NavItemData(
        label: chatLabel,
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome,
      ),
    ];

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: bottomSafePadding > 0 ? bottomSafePadding + 6 : 14,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (idx) {
                  final item = navItems[idx];
                  final isActive = selectedIndex == idx;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabSelected(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          vertical: isActive ? 4 : 6,
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryMedium : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryMedium.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 20,
                              color: isActive ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                color: isActive ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
