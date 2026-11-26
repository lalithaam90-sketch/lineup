import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Small "LineUp" wordmark used in headers (e.g. the home screen's hero
/// header). Reconstructed from its usage elsewhere in the app — the
/// original file wasn't recoverable, so this is a clean rebuild matching
/// the same constructor (size / isDark / showShadow) and the app's theme.
class LineUpLogo extends StatelessWidget {
  final double size;
  final bool isDark;
  final bool showShadow;

  const LineUpLogo({
    super.key,
    this.size = 32,
    this.isDark = false,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white : AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.accentLightMint,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(Icons.bolt_rounded, color: iconColor, size: size * 0.6),
        ),
        SizedBox(width: size * 0.28),
        Text(
          'LineUp',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
