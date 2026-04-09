import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════
//  AROGYASATHI — SHARED WIDGET LIBRARY
// ═══════════════════════════════════════════════

// ── Section Header ────────────────────────────────
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          if (actionLabel != null && actionLabel!.isNotEmpty)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── App Card ──────────────────────────────────────
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
    return Material(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.teal.withValues(alpha: 0.04),
        highlightColor: AppColors.teal.withValues(alpha: 0.02),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: AppColors.cardShadow,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Status Pill ───────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ── Navy Section Header (full-width label) ─────────
class NavySectionLabel extends StatelessWidget {
  final String label;

  const NavySectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}

// ── Pill Toggle (custom animated switch) ──────────
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
          color: _value ? AppColors.teal : AppColors.border,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Vital Card ────────────────────────────────────
class VitalCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final String subLabel;
  final Color accent;
  final Color accentBg;

  const VitalCard({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.subLabel,
    required this.accent,
    required this.accentBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: AppColors.cardShadow,
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(kRadiusSm)),
            child: Icon(icon, color: accent, size: 16),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  )),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(unit,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          Text(subLabel,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }
}

// ── Quick Action Button ───────────────────────────
class QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
  // Legacy emoji param kept for compat but ignored
  final String? emoji;

  const QuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kRadius),
              boxShadow: AppColors.cardShadow,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 0.5),
            ),
            child: Center(
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(kRadiusSm)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Water Tracker Dot ─────────────────────────────
class WaterCup extends StatelessWidget {
  final bool filled;
  final VoidCallback onTap;

  const WaterCup({super.key, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.tealPale : Colors.transparent,
          border: Border.all(
            color: filled ? AppColors.teal : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.water_drop,
          size: 14,
          color: filled ? AppColors.teal : AppColors.border,
        ),
      ),
    );
  }
}

// ── Stat Mini Card (legacy compat) ─────────────────
class StatMiniCard extends StatelessWidget {
  final String emoji;          // kept for compat, not shown
  final IconData? icon;
  final String value;
  final String unit;
  final String label;
  final String subLabel;
  final Color accentColor;

  const StatMiniCard({
    super.key,
    this.emoji = '',
    this.icon,
    required this.value,
    this.unit = '',
    required this.label,
    required this.subLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return VitalCard(
      icon: icon ?? Icons.monitor_heart_outlined,
      value: value,
      unit: unit,
      label: label,
      subLabel: subLabel,
      accent: accentColor,
      accentBg: accentColor.withValues(alpha: 0.1),
    );
  }
}

// ── Horizontal Divider with Label ──────────────────
class LabelledDivider extends StatelessWidget {
  final String label;
  const LabelledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
        ),
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      ]),
    );
  }
}

// ── Profile Info Row ──────────────────────────────
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(kRadiusSm)),
            child: Icon(icon, size: 17, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(value,  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
          trailing ?? const Icon(Icons.chevron_right, size: 18, color: AppColors.border),
        ]),
      ),
    );
  }
}
