import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:marvel_travel/core/theme/app_theme.dart';

class AuroraNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AuroraNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AuroraNavBar> createState() => _AuroraNavBarState();
}

class _AuroraNavBarState extends State<AuroraNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  static const _colors = [
    AuroraColors.auroraGreen,
    AuroraColors.auroraBlue,
    AuroraColors.auroraTeal,
    AuroraColors.auroraPurple,
    AuroraColors.auroraPink,
  ];
  static const _icons = [
    Icons.home_rounded,
    Icons.map_rounded,
    Icons.search_rounded,
    Icons.bookmark_rounded,
    Icons.person_rounded,
  ];
  static const _iconsOut = [
    Icons.home_outlined,
    Icons.map_outlined,
    Icons.search_outlined,
    Icons.bookmark_outline,
    Icons.person_outline,
  ];
  static const _labels = ['Home', 'Map', 'Search', 'Bookmark', 'Profile'];

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  List<Color> _auroraBackground(double t) {
    final waveA = (math.sin(t * math.pi * 2) + 1) / 2;
    final waveB = (math.sin(t * math.pi * 2 + math.pi / 2) + 1) / 2;

    return [
      Color.lerp(const Color(0xFF081118), const Color(0xFF10202A), waveA)!,
      Color.lerp(const Color(0xFF0D1A24), AuroraColors.auroraTeal, waveB)!
          .withValues(alpha: 0.86),
      Color.lerp(AuroraColors.auroraBlue, AuroraColors.auroraPurple, waveA)!
          .withValues(alpha: 0.68),
      Color.lerp(AuroraColors.auroraGreen, AuroraColors.auroraPink, waveB)!
          .withValues(alpha: 0.40),
      const Color(0xFF05080C),
    ];
  }

  Color _adaptiveForeground(Color background) {
    return background.computeLuminance() > 0.42 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final bgColors = _auroraBackground(_shimmer.value);
        final sampledBg = Color.lerp(bgColors[1], bgColors[2], 0.5)!;
        final contrastBase = _adaptiveForeground(sampledBg);
        final inactiveColor = contrastBase.withValues(
          alpha: contrastBase == Colors.white ? 0.78 : 0.70,
        );
        return Container(
          height: 84,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: _colors[widget.currentIndex].withValues(alpha: 0.42),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: _colors[widget.currentIndex].withValues(alpha: 0.24),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: bgColors,
                      stops: const [0.0, 0.28, 0.56, 0.82, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.26),
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final selected = widget.currentIndex == i;
                  final color = _colors[i];
                  final activeFg =
                      Color.lerp(contrastBase, Colors.white, 0.45)!;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: selected ? 46 : 34,
                              height: selected ? 30 : 24,
                              decoration: selected
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.42),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.38),
                                          blurRadius: 10,
                                          spreadRadius: -1,
                                        ),
                                      ],
                                    )
                                  : null,
                              child: Center(
                                child: selected
                                    ? Icon(
                                        _icons[i],
                                        color: activeFg,
                                        size: 20,
                                      )
                                    : Icon(
                                        _iconsOut[i],
                                        color: inactiveColor,
                                        size: 19,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: selected ? 10.5 : 9.5,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                letterSpacing: 0.15,
                                color: selected ? activeFg : inactiveColor,
                                shadows: [
                                  Shadow(
                                    color: selected
                                        ? Colors.black.withValues(alpha: 0.75)
                                        : Colors.black.withValues(alpha: 0.50),
                                    blurRadius: selected ? 8 : 4,
                                  ),
                                  if (selected)
                                    Shadow(
                                      color: color.withValues(alpha: 0.70),
                                      blurRadius: 10,
                                    ),
                                ],
                              ),
                              child: Container(
                                padding: selected
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      )
                                    : EdgeInsets.zero,
                                decoration: selected
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      )
                                    : null,
                                child: Text(_labels[i]),
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: selected ? 16 : 0,
                              height: selected ? 2 : 0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    color,
                                    Colors.transparent
                                  ],
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.9),
                                          blurRadius: 5,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
