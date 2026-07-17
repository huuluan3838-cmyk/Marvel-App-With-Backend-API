import 'package:flutter/material.dart';

import 'package:marvel_travel/core/theme/app_theme.dart';

enum MarvelThemeMode { light, system, dark }

class MarvelAppBar extends StatelessWidget {
  final bool isScrolled;
  final bool isDark;
  final MarvelThemeMode currentTheme;
  final ValueChanged<MarvelThemeMode> onThemeChanged;
  final VoidCallback? onMenuTap;

  const MarvelAppBar({
    super.key,
    required this.isScrolled,
    required this.isDark,
    required this.currentTheme,
    required this.onThemeChanged,
    this.onMenuTap,
  });

  Color _iconColor(MarvelThemeMode mode) {
    if (currentTheme == mode) return const Color(0xFF0D832B);
    if (isScrolled) return isDark ? Colors.white60 : Colors.black45;
    return Colors.white60;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isScrolled
            ? (isDark
                ? AuroraColors.deepSpace.withValues(alpha: 0.97)
                : AppColors.navBarBg.withValues(alpha: 0.97))
            : Colors.transparent,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 1),
                ),
              ]
            : [],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo2.jpg',
                      fit: BoxFit.scaleDown,
                      cacheWidth: 150,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF32D445), Color(0xFF004311)],
                          ),
                        ),
                        child: const Icon(
                          Icons.landscape,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: marvelTitleStops,
                    colors: marvelTitleColors,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Text('Marvel', style: AppTextStyles.appBarTitle),
                ),
                const Spacer(),
                Container(
                  width: 107,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isScrolled
                        ? (isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.06))
                        : Colors.white24,
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => onThemeChanged(MarvelThemeMode.light),
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.wb_sunny_outlined,
                          color: _iconColor(MarvelThemeMode.light),
                          size: 17,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onThemeChanged(MarvelThemeMode.system),
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.smartphone,
                          color: _iconColor(MarvelThemeMode.system),
                          size: 17,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onThemeChanged(MarvelThemeMode.dark),
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.nightlight_outlined,
                          color: _iconColor(MarvelThemeMode.dark),
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onMenuTap,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        Icons.menu,
                        color: isScrolled
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
