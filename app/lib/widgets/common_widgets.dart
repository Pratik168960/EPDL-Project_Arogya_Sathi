import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Section Header ────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluePrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── App Card ──────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = kRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppColors.bluePrimary.withOpacity(0.05),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ──────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Gradient Header ───────────────────────────────
class GradientHeader extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsets? padding;

  const GradientHeader({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: 20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─── Pill Toggle ───────────────────────────────────
class PillToggle extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const PillToggle({super.key, this.initialValue = true, this.onChanged});

  @override
  State<PillToggle> createState() => _PillToggleState();
}

class _PillToggleState extends State<PillToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _value = !_value);
        widget.onChanged?.call(_value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: _value ? AppColors.greenPrimary : AppColors.border,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Water Cup Widget ──────────────────────────────
class WaterCup extends StatelessWidget {
  final bool filled;
  final VoidCallback onTap;

  const WaterCup({super.key, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? AppColors.blueLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? AppColors.bluePrimary : AppColors.border,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '🥛',
            style: TextStyle(fontSize: filled ? 20 : 18),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Mini Card ────────────────────────────────
class StatMiniCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String unit;
  final String label;
  final String subLabel;
  final Color accentColor;

  const StatMiniCard({
    super.key,
    required this.emoji,
    required this.value,
    this.unit = '',
    required this.label,
    required this.subLabel,
    required this.accentColor,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12), // Reduced from 16 to 12 to give text more room
      child: Stack(
        children: [
          Positioned(
            bottom: -10, right: -10,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          FittedBox( // Wraps the column to scale it down slightly if it gets too tight
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Stops vertical stretching
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4), // Reduced spacing slightly
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1,
                        )),
                    if (unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 1),
                        child: Text(unit,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    )),
                Text(subLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Item ─────────────────────────────
class QuickActionItem extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  const QuickActionItem({
    super.key,
    required this.emoji,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Stops it from expanding infinitely
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: cardShadow,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
